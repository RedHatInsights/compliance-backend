# frozen_string_literal: true

require 'test_helper'
require 'xccdf/benchmarks'

module Xccdf
  # A class to test Xccdf::Benchmarks
  class BenchmarksTest < ActiveSupport::TestCase
    OP_BENCHMARK = OpenStruct.new(id: '1', version: 'v0.1.49',
                                  title: 'one', description: 'first')

    class Mock
      include Xccdf::Util

      def initialize(op_benchmark)
        @op_benchmark = op_benchmark
      end
    end

    test 'save_benchmark' do
      mock = Mock.new(OP_BENCHMARK)
      assert_difference('Xccdf::Benchmark.count', 1) do
        mock.save_benchmark
      end
      assert mock.benchmark_saved?
    end

    test 'does not try to save an existing benchmark' do
      mock = Mock.new(OP_BENCHMARK)
      mock.save_benchmark
      assert mock.benchmark_saved?

      mock.expects(:save_benchmark).never
      assert_no_difference('Xccdf::Benchmark.count') do
        mock.save_all_benchmark_info
      end
      assert mock.benchmark_saved?
    end
  end
end
