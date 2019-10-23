# frozen_string_literal: true

module Xccdf
  # Methods related to saving xccdf benchmarks
  module Benchmarks
    extend ActiveSupport::Concern

    included do
      def save_benchmark
        @benchmark = ::Xccdf::Benchmark.from_openscap_parser(@op_benchmark)
        ::Xccdf::Benchmark.import!([@benchmark].select(&:new_record?),
                                   ignore: true)
      end
    end
  end
end
