# frozen_string_literal: true

module Xccdf
  # Stores information about xccdf benchmarks. This comes from SCAP
  # <Benchmark /> which records which define all rules, profiles, and variables
  # for a given set of software in a specific release of the SCAP Security
  # Guide (i.e. RHEL 7, v0.1.43)
  class Benchmark < ApplicationRecord
    scoped_search on: %i[id ref_id title version]
    scoped_search relation: :profiles, on: :id, rename: :profile_ids,
                  aliases: %i[profile_id]
    scoped_search relation: :rules, on: :id, rename: :rule_ids,
                  aliases: %i[rule_id]
    scoped_search on: :os_major_version, ext_method: 'os_major_version_search',
                  only_explicit: true, operators: ['=', '!='],
                  validator: ScopedSearch::Validators::INTEGER

    has_many :profiles, dependent: :destroy
    has_many :rules, dependent: :destroy
    validates :ref_id, uniqueness: { scope: %i[version] }, presence: true
    validates :version, presence: true

    LATEST_SUPPORTED_VERSIONS = {
      'xccdf_org.ssgproject.content_benchmark_RHEL-6': '0.1.28',
      # RHEL 7 with CIS backported to 0.1.49 in downstream
      'xccdf_org.ssgproject.content_benchmark_RHEL-7': '0.1.50',
      'xccdf_org.ssgproject.content_benchmark_RHEL-8': '0.1.48'
    }.freeze

    scope :os_major_version, lambda { |major, equals = true|
      where(os_major_version_query(major, equals))
    }

    class << self
      def os_major_version_like_condition(major)
        "%RHEL-#{major}"
      end

      def os_major_version_query(major, equals)
        ref_id = arel_table[:ref_id]
        condition = os_major_version_like_condition(major)
        equals ? ref_id.matches(condition) : ref_id.does_not_match(condition)
      end

      def os_major_version_search(_filter, operator, value)
        equals = operator == '=' ? ' ' : ' NOT '
        { conditions: "ref_id#{equals}like ?",
          parameter: [os_major_version_like_condition(value)] }
      end

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

      def latest
        select(
          'DISTINCT ref_id, version, id, title'
        ).group_by(&:ref_id).map do |_, benchmarks|
          find_latest(benchmarks)
        end
      end

      def find_latest(benchmarks)
        benchmarks.max_by do |benchmark|
          Gem::Version.new(benchmark.version)
        end
      end

      def latest_supported
        Rails.cache.fetch('latest_supported_benchmarks') do
          LATEST_SUPPORTED_VERSIONS.inject(
            where('1=0')
          ) do |acc, (ref_id, version)|
            acc.or(where(ref_id: ref_id, version: version))
          end.compact
        end
      end
    end

    def inferred_os_major_version
      ref_id[/(?<=RHEL-)\d/]
    end
    alias os_major_version inferred_os_major_version
  end
end
