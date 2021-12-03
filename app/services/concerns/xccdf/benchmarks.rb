# frozen_string_literal: true

module Xccdf
  # Methods related to saving xccdf benchmarks
  module Benchmarks
    extend ActiveSupport::Concern

    included do
      def save_benchmark
        benchmark.package_name = package_name

        return unless benchmark.new_record? || benchmark.package_name_changed?

        benchmark.save!
      end

      def benchmark_saved?
        benchmark.package_name == package_name && benchmark.persisted?
      end

      def benchmark_profiles_saved?
        benchmark.profiles.canonical.count == @op_benchmark.profiles.count
      end

      def benchmark_rules_saved?
        benchmark.rules.count == @op_benchmark.rules.count
      end

      def benchmark_contents_equal_to_op?
        return false if Settings.force_import_ssgs

        benchmark_saved? && benchmark_rules_saved? && benchmark_profiles_saved?
      end

      def benchmark
        @benchmark ||= ::Xccdf::Benchmark.from_openscap_parser(@op_benchmark)
      end

      def package_name
        @package_name ||= begin
          SupportedSsg.by_os_major[benchmark.os_major_version].find do |item|
            item.version == benchmark.version
          end&.package
        end
      end
    end
  end
end
