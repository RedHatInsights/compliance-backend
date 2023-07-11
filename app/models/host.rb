# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

# Host representation in insights compliance backend. Most of the times
# these hosts will also show up in the insights-platform host inventory.
class Host < ApplicationRecord
  OS_VERSION = Arel::Nodes::InfixOperation.new(
    '->',
    Host.arel_table[:system_profile],
    Arel::Nodes::Quoted.new('operating_system')
  )
  OS_MINOR_VERSION = Arel::Nodes::InfixOperation.new(
    '->',
    OS_VERSION,
    Arel::Nodes::Quoted.new('minor')
  )
  OS_MAJOR_VERSION = Arel::Nodes::InfixOperation.new(
    '->',
    OS_VERSION,
    Arel::Nodes::Quoted.new('major')
  )
  TAGS = Arel::Nodes::NamedFunction.new(
    'jsonb_array_elements',
    [Host.arel_table[:tags]]
  )
  JOIN_NO_BENCHMARK = arel_table.join(
    Xccdf::Benchmark.arel_table,
    Arel::Nodes::OuterJoin
  ).on(Arel::Nodes::False.new).join_sources

  sortable_by :name, :display_name
  sortable_by :score, Arel::Nodes::NamedFunction.new(
    'COALESCE',
    [TestResult.arel_table[:score]]
  ), scope: :joins_test_result_profiles
  sortable_by :os_major_version, OS_MAJOR_VERSION
  sortable_by :os_minor_version, OS_MINOR_VERSION
  sortable_by(
    :ssg_version,
    Arel::Nodes::NamedFunction.new(
      'CAST',
      [
        Arel::Nodes::NamedFunction.new(
          'string_to_array',
          [
            Xccdf::Benchmark.arel_table[:version],
            Arel::Nodes::Quoted.new('.')
          ]
        ).as('int[]')
      ]
    ),
    scope: :with_benchmark
  )

  sortable_by :rules_failed, Arel::Nodes::NamedFunction.new(
    'COALESCE',
    [Arel::Nodes::SqlLiteral.new('sq.rules_failed'), 0]
  ), scope: :with_failed_rules_count

  self.table_name = 'inventory.hosts'
  self.primary_key = 'id'

  include HostSearching

  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results, source: :rule
  has_many :policy_hosts, dependent: :destroy
  has_many :test_results, dependent: :destroy
  include SystemLike

  has_many :test_result_profiles, -> { distinct },
           through: :test_results, source: :profile
  has_many :policies, through: :policy_hosts
  has_many :assigned_profiles, through: :policies, source: :profiles
  has_many :assigned_internal_profiles, -> { external(false) },
           through: :policies, source: :profiles

  scope :with_benchmark, lambda { |profile = nil|
    profile ||= RequestStore.store['scoped_search_context_profiles']

    # Join with nonexisting benchmarks if the hosts aren't scoped for a policy
    return joins(JOIN_NO_BENCHMARK) if profile.nil?

    left_outer_joins(test_result_profiles: :benchmark).where(
      profiles: { id: profile.pluck(:id) }
    )
  }

  scope :joins_test_result_profiles, lambda {
    left_outer_joins(:test_result_profiles)
  }

  scope :with_failed_rules_count, lambda { |profile = nil|
    profile ||= RequestStore.store['scoped_search_context_profiles']
    profile_ids = profile&.pluck(:id) || []

    sq = Host.joins(test_results: :rule_results)
             .merge(TestResult.latest)
             .where(test_results: { profile_id: profile_ids }, rule_results: { result: RuleResult::FAILED })
             .or(Host.where(test_results: { profile_id: profile_ids }, rule_results: { id: nil }))
             .select(arel_table[:id].as('id'), RuleResult.arel_table[:result].count.as('rules_failed'))
             .group('hosts.id')

    joins("LEFT OUTER JOIN (#{sq.to_sql}) sq ON sq.id = hosts.id")
  }

  def self.os_minor_versions(hosts)
    distinct.where(id: hosts).pluck(OS_MINOR_VERSION)
  end

  def self.available_os_versions
    distinct.pluck(OS_VERSION)
  end

  def readonly?
    true
  end

  def self.taggable?
    true
  end

  def self.os_version_query(path, values, equal = true)
    query = equal ? :in : :not_in

    raise ArgumentError unless %i[major minor].include?(path)

    Arel::Nodes::InfixOperation.new(
      '->',
      arel_table[:system_profile],
      Arel::Nodes::SqlLiteral.new("'operating_system'->'#{path}'")
    ).send(query, values)
  end

  alias destroy save
  alias delete save

  def policy_hosts?
    policy_hosts.any?
  end
  alias has_policy policy_hosts?

  def os_major_version
    system_profile&.dig('operating_system', 'major')
  end

  def os_minor_version
    system_profile&.dig('operating_system', 'minor')
  end

  def name
    display_name
  end

  def all_profiles
    Profile.where(id: assigned_profiles)
           .or(Profile.where(id: test_result_profiles))
           .distinct
  end
end

# rubocop:enable Metrics/ClassLength
