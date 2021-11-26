# frozen_string_literal: true

module Xccdf
  # Stores information about xccdf benchmarks. This comes from SCAP
  # <Benchmark /> which records which define all rules, profiles, and variables
  # for a given set of software in a specific release of the SCAP Security
  # Guide (i.e. RHEL 7, v0.1.43)
  class Benchmark < ApplicationRecord
    has_many :profiles, dependent: :destroy
    has_many :rules, dependent: :destroy
    validates :ref_id, uniqueness: { scope: %i[version] }, presence: true
    validates :version, presence: true

    sortable_by :title
    sortable_by :version, Arel.sql("string_to_array(version, '.')::int[]")

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

    # Returns all supported profiles for a given OS major version
    # through a benchmark referencing this OS major
    def supported_profiles
      versions = SupportedSsg.by_os_major[os_major_version].map(&:version)

      Profile.canonical.joins(:benchmark)
             .where(benchmarks: { ref_id: ref_id, version: versions })
             .order(:ref_id, Arel.sql('
                string_to_array("benchmarks"."version", \'.\')::int[] DESC
              '))
             .select('DISTINCT ON ("profiles"."ref_id") "profiles".*')
    end

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
