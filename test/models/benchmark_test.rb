# frozen_string_literal: true

require 'test_helper'

module Xccdf
  # To test the Xccdf::Benchmark model
  class BenchmarkTest < ActiveSupport::TestCase
    should validate_uniqueness_of(:ref_id).scoped_to(:version)
    should validate_presence_of :ref_id
    should validate_presence_of :version
    should have_many(:profiles)
    should have_many(:rules)

    OP_BENCHMARK = OpenStruct.new(id: '1', version: 'v0.1.49',
                                  title: 'one', description: 'first')

    test 'builds a Benchmark from_openscap_parser OpenscapParser::Benchmark' do
      benchmark = Benchmark.from_openscap_parser(OP_BENCHMARK)
      assert_equal OP_BENCHMARK.id, benchmark.ref_id
      assert_equal OP_BENCHMARK.version, benchmark.version
      assert_equal OP_BENCHMARK.title, benchmark.title
      assert_equal OP_BENCHMARK.description, benchmark.description
      assert benchmark.save
      assert_equal benchmark.id, Benchmark.from_openscap_parser(OP_BENCHMARK).id
    end

    test 'inferred_os_major_version' do
      OP_BENCHMARK[:id] = 'xccdf_org.ssgproject.content_benchmark_RHEL-7'
      benchmark = Benchmark.from_openscap_parser(OP_BENCHMARK)

      assert_equal '7', benchmark.inferred_os_major_version
    end

    test 'return latest benchmarks for all ref_ids' do
      Xccdf::Benchmark.create(ref_id: 'rhel7', version: '0.1.40',
                              title: 'foo1', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel7', version: '0.1.41',
                              title: 'foo2', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel7', version: '0.2.0',
                              title: 'foo3', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel6', version: '0.1.42',
                              title: 'foo4', description: 'a')
      Xccdf::Benchmark.create(ref_id: 'rhel8', version: '0.2.2',
                              title: 'foo5', description: 'a')

      latest = Xccdf::Benchmark.latest
      assert latest.count == 4
      assert_equal %w[rhel6 rhel7 rhel8
                      xccdf_org.ssgproject.content_benchmark_RHEL-7],
                   latest.map(&:ref_id).sort
      assert_equal %w[0.1.42 0.1.43 0.2.0 0.2.2],
                   latest.map(&:version).sort
    end
  end
end
