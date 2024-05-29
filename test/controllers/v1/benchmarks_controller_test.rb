# frozen_string_literal: true

require 'test_helper'

module V1
  class BenchmarksControllerTest < ActionDispatch::IntegrationTest
    setup do
      BenchmarksController.any_instance.stubs(:authenticate_user).yields
      User.current = FactoryBot.create(:user)
      @hosts = FactoryBot.create_list(:host, 2)
    end

    test '#index success' do
      get v1_benchmarks_url
      assert_response :success
    end

    test '#show success' do
      bm1 = FactoryBot.create(:benchmark)
      stub_supported_ssg(@hosts, [bm1.version])
      get v1_benchmarks_url(bm1)
      assert_response :success
    end

    test '#index includes rules' do
      bm1 = FactoryBot.create(:benchmark)
      stub_supported_ssg(@hosts, [bm1.version])
      FactoryBot.create(:rule, benchmark: bm1)
      get v1_benchmarks_url, params: { include: 'rules' }
      assert_response :success
      assert_equal(response.parsed_body['included'].first['type'], 'rule')
    end

    test '#index does not include rule_tree' do
      bm1 = FactoryBot.create(:benchmark)
      stub_supported_ssg(@hosts, [bm1.version])
      Xccdf::Benchmark.any_instance.stubs(:rule_tree).returns('foo')
      get v1_benchmarks_url
      assert_response :success
      assert_nil response.parsed_body['data'][0]['attributes']['rule_tree']
    end

    test '#show includes rule_tree' do
      bm1 = FactoryBot.create(:benchmark)
      Xccdf::Benchmark.any_instance.expects(:rule_tree).returns('foo')
      stub_supported_ssg(@hosts, [bm1.version])
      get v1_benchmark_url(bm1)
      assert_response :success
      assert_equal response.parsed_body['data']['attributes']['rule_tree'], 'foo'
    end

    test 'fails when includes nested' do
      FactoryBot.create(:rule, benchmark: FactoryBot.create(:benchmark))
      get v1_benchmarks_url, params: { include: 'rules.benchmark' }
      assert_response :unprocessable_entity
      assert_match('Invalid parameter:', response.parsed_body['errors'].first)
    end

    test 'fails when includes invalid' do
      FactoryBot.create(:rule, benchmark: FactoryBot.create(:benchmark))
      get v1_benchmarks_url, params: { include: 'ducktales,benchmark' }
      assert_response :unprocessable_entity
      assert_match('Invalid parameter:', response.parsed_body['errors'].first)
    end

    test 'benchmarks can be sorted' do
      b1 = FactoryBot.create(:benchmark, title: 'a', version: '0.2')
      b2 = FactoryBot.create(:benchmark, title: 'a', version: '1.0')
      b3 = FactoryBot.create(:benchmark, title: 'a', version: '0.9')
      b4 = FactoryBot.create(:benchmark, title: 'b', version: '0.1')
      stub_supported_ssg(@hosts, [b1.version, b2.version, b3.version, b4.version])

      get v1_benchmarks_url, params: {
        sort_by: %w[title version]
      }
      assert_response :success

      benchmarks = response.parsed_body['data']

      assert_equal(benchmarks.map { |b| b['id'] }, [b1, b3, b2, b4].map(&:id))
    end
  end
end
