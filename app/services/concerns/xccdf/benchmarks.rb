# frozen_string_literal: true

module Xccdf
  # Methods related to saving xccdf benchmarks
  module Benchmarks
    extend ActiveSupport::Concern

    included do
      def save_benchmark
        ::Xccdf::Benchmark.import!([benchmark].select(&:new_record?),
                                   ignore: true)
      end

      def benchmark_saved?
        benchmark.persisted?
      end

      def benchmark_profiles_saved?
        benchmark.profiles.canonical.count == @op_benchmark.profiles.count
      end

      def benchmark_rules_saved?
        benchmark.rules.count == @op_benchmark.rules.count
      end

      def benchmark_contents_equal_to_op?
        benchmark_saved? && benchmark_rules_saved? && benchmark_profiles_saved?
      end

      def benchmark
        @benchmark ||= ::Xccdf::Benchmark.from_openscap_parser(@op_benchmark)
      end
    end
  end
end
