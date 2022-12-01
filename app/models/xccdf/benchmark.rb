# frozen_string_literal: true

module Xccdf
  # Stores information about xccdf benchmarks. This comes from SCAP
  # <Benchmark /> which records which define all rules, profiles, and variables
  # for a given set of software in a specific release of the SCAP Security
  # Guide (i.e. RHEL 7, v0.1.43)
  class Benchmark < ApplicationRecord
    include RulesAndRuleGroups

    REF_PREFIX = 'xccdf_org.ssgproject.content_benchmark_RHEL'
    SORT_BY_VERSION = Arel::Nodes::NamedFunction.new(
      'CAST',
      [
        Arel::Nodes::NamedFunction.new(
          'string_to_array',
          [arel_table[:version], Arel::Nodes::Quoted.new('.')]
        ).as('int[]')
      ]
    )

    has_many :profiles, dependent: :destroy
    has_many :rules, dependent: :destroy
    has_many :value_definitions, dependent: :destroy
    has_many :rule_groups, -> { order(:precedence) }, dependent: :destroy, inverse_of: :benchmark
    validates :ref_id, uniqueness: { scope: %i[version] }, presence: true
    validates :version, presence: true

    scope :including_profile, lambda { |profile|
      joins(:profiles).where(profiles: { parent_profile_id: nil,
                                         ref_id: profile.ref_id,
                                         upstream: false })
    }

    sortable_by :title
    # Ordering by hash can't deal with Arel, so this juggling is necessary
    sortable_by :version, SORT_BY_VERSION

    include ::BenchmarkSearching

    def latest_supported_os_minor_versions
      latest_per_minor = SupportedSsg.latest_map[os_major_version]
      return [] unless latest_per_minor

      latest_per_minor.select do |_k, ssg|
        ssg.version == version
      end.keys
    end

    def inferred_os_major_version
      ref_id[/(?<=RHEL-)\d/]
    end
    alias os_major_version inferred_os_major_version

    class << self
      def from_openscap_parser(op_benchmark)
        benchmark = find_or_initialize_by(
          ref_id: op_benchmark.id,
          version: op_benchmark.version
        )

        benchmark.assign_attributes(
          title: op_benchmark.title,
          description: op_benchmark.description
        )

        benchmark
      end

      def policy_class
        BenchmarkPolicy
      end
    end
  end
end
