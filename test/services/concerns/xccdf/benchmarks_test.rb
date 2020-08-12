# frozen_string_literal: true

require 'test_helper'
require 'xccdf/benchmarks'

module Xccdf
  # A class to test Xccdf::Benchmarks
  class BenchmarksTest < ActiveSupport::TestCase
    OP_BENCHMARK = OpenStruct.new(id: '1', version: 'v0.1.49',
                                  title: 'one', description: 'first',
                                  profiles: ['profile-mock1'],
                                  rules: ['rule-mock1'])

    class Mock
      include Xccdf::Util

      def initialize(op_benchmark)
        @op_benchmark = op_benchmark
      end

      def rules
        ['rule-mock']
      end
    end

    test 'save_benchmark' do
      mock = Mock.new(OP_BENCHMARK)
      ::Xccdf::Benchmark.any_instance.expects(:rules)
                        .returns(['rule-mock1']).at_least_once
      ::Xccdf::Benchmark.any_instance.expects(:profiles)
                        .returns(stub(canonical: ['profile-mock1']))
                        .at_least_once
      assert_difference('Xccdf::Benchmark.count', 1) do
        mock.save_benchmark
      end
      assert mock.benchmark_contents_equal_to_op?
    end

    test 'does not try to save an existing benchmark' do
      mock = Mock.new(OP_BENCHMARK)
      ::Xccdf::Benchmark.any_instance.expects(:rules)
                        .returns(['rule-mock1']).at_least_once
      ::Xccdf::Benchmark.any_instance.expects(:profiles)
                        .returns(stub(canonical: ['profile-mock1']))
                        .at_least_once
      mock.save_benchmark
      assert mock.benchmark_contents_equal_to_op?

      mock.expects(:save_benchmark).never
      assert_no_difference('Xccdf::Benchmark.count') do
        mock.save_all_benchmark_info
      end
      assert mock.benchmark_contents_equal_to_op?
    end

    test 'benchmark is not saved if rules count differ' do
      mock = Mock.new(OP_BENCHMARK)
      assert_not_equal mock.benchmark.rules.count, OP_BENCHMARK.rules.count
      assert_not mock.benchmark_contents_equal_to_op?
    end

    test 'benchmark is not saved if profiles count differ' do
      mock = Mock.new(OP_BENCHMARK)
      ::Xccdf::Benchmark.any_instance.expects(:profiles)
                        .returns(%w[profiles-mock1 mock2]).at_least_once
      assert_not_equal mock.benchmark.profiles.count,
                       OP_BENCHMARK.profiles.count
      assert_not mock.benchmark_contents_equal_to_op?
    end
  end
end
