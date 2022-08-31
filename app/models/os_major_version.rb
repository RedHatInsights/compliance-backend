# frozen_string_literal: true

# Pseudo-class for retrieving supported OS major versions
class OsMajorVersion < ApplicationRecord
  self.table_name = 'benchmarks'

  # Helper function that aggregates a column under a grouping and orders them
  # descending based on their benchmark version.
  def self.aggregated_cast(column)
    Arel::Nodes::NamedFunction.new(
      'array_agg',
      [Arel::Nodes::InfixOperation.new(
        'ORDER BY',
        column,
        Arel::Nodes::Descending.new(
          Xccdf::Benchmark::SORT_BY_VERSION
        )
      )]
    )
  end

  OS_MAJOR_VERSION = Arel::Nodes::NamedFunction.new(
    'CAST',
    [
      Arel::Nodes::NamedFunction.new(
        'REPLACE',
        [
          arel_table[:ref_id],
          Arel::Nodes::Quoted.new("#{Xccdf::Benchmark::REF_PREFIX}-"),
          Arel::Nodes::Quoted.new('')
        ]
      ).as('int')
    ]
  ).as('os_major_version')

  PROFILE_IN_USE = Arel::Nodes::True.new.as('in_use')
  PROFILE_LAST_ID = Arel.sql("(#{aggregated_cast(Profile.arel_table[:id]).to_sql})[1] as \"id\"")
  PROFILE_BM_VERSIONS = aggregated_cast(arel_table[:version]).as('bm_versions')
  # Rails tries to alias the JOIN on benchmarks as it wrongly detects multiple use across subqueries, in order
  # to prevent this from happening, we're generating the join explicitly using Arel.
  PROFILE_BM_JOIN = Profile.arel_table.join(arel_table).on(Profile.arel_table[:benchmark_id].eq(arel_table[:id]))

  default_scope do
    select(OS_MAJOR_VERSION, :ref_id).distinct.order(:os_major_version)
  end

  has_many :benchmarks, class_name: 'Xccdf::Benchmark',
                        foreign_key: 'ref_id', primary_key: 'ref_id',
                        inverse_of: false, dependent: :restrict_with_exception

  has_many :profiles, lambda {
    # List the profiles in use for the current user
    profiles_in_use = User.current.account.profiles.joins(PROFILE_BM_JOIN.join_sources)
                          .select(arel_table[:ref_id], OS_MAJOR_VERSION, PROFILE_IN_USE)

    # Canonical profiles joined with profiles in use and grouped by supported benchmark versions
    supported_profiles = canonical.where(upstream: false)
                                  .joins(PROFILE_BM_JOIN.join_sources)
                                  .joins("LEFT OUTER JOIN (#{profiles_in_use.to_sql}) sq ON
                                    sq.ref_id = profiles.ref_id AND
                                    os_major_version = sq.os_major_version")
                                  .select(PROFILE_LAST_ID, PROFILE_BM_VERSIONS, OS_MAJOR_VERSION, 'sq.in_use')
                                  .group(:ref_id, Xccdf::Benchmark.arel_table[:ref_id], 'in_use')

    # Rails cannot consume grouped results as proper ActiveRecord classes, it has to be joined with itself
    canonical.where(upstream: false)
             .joins("INNER JOIN (#{supported_profiles.to_sql}) t ON t.id = profiles.id")
             .select('"profiles".*, "t"."bm_versions" AS "bm_versions"',
                     '"t"."os_major_version" AS "os_major_version"',
                     'COALESCE("t"."in_use", FALSE) AS "in_use"')
  }, through: :benchmarks

  def readonly?
    true
  end

  def os_major_version
    attributes['os_major_version']
  end
end
