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
