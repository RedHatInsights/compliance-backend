# frozen_string_literal: true

require 'test_helper'

class BenchmarkQueryTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  test 'query all benchmarks' do
    benchmarks = FactoryBot.create_list(:benchmark, 3)

    query = <<-GRAPHQL
      query Benchmarks {
          benchmarks {
              nodes {
                  id
              }
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: @user }
    )

    assert_equal(
      benchmarks.count, result.dig('data', 'benchmarks', 'nodes').count
    )
    assert_equal(
      benchmarks.pluck(:id).sort,
      result.dig('data', 'benchmarks', 'nodes').map { |n| n['id'] }.sort
    )
  end

  test 'query benchmarks with a filter' do
    query = <<-GRAPHQL
      query Benchmarks {
          benchmarks {
              nodes {
                  id
              }
          }
      }
    GRAPHQL

    os_major_version = FactoryBot.create(:benchmark).os_major_version
    filtered_benchmarks = Xccdf::Benchmark.os_major_version(os_major_version)
    result = Schema.execute(
      query,
      variables: {
        filter: "os_major_version=#{os_major_version}"
      },
      context: { current_user: @user }
    )

    assert_equal(
      filtered_benchmarks.count,
      result.dig('data', 'benchmarks', 'nodes').count
    )
    assert_equal(
      filtered_benchmarks.pluck(:id).sort,
      result.dig('data', 'benchmarks', 'nodes').map { |n| n['id'] }.sort
    )
  end

  test 'query latest benchmarks' do
    supported_ssg = SupportedSsg.new(version: '0.1.50',
                                     os_major_version: '7',
                                     os_minor_version: '3')
    SupportedSsg.stubs(:by_os_major)
                .returns('7' => [supported_ssg])

    latest_benchmark = ::Xccdf::Benchmark.create(
      ref_id: supported_ssg.ref_id,
      version: supported_ssg.version,
      title: 'sample',
      description: 'sample description'
    )
    query = <<-GRAPHQL
      query latestBenchmarks {
          latestBenchmarks {
              id
              title
              refId
              version
              osMajorVersion
              profiles {
                  id
              }
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: @user }
    )

    assert_equal latest_benchmark.id,
                 result['data']['latestBenchmarks'].first['id']
    assert_equal latest_benchmark.title,
                 result['data']['latestBenchmarks'].first['title']
    assert_equal latest_benchmark.ref_id,
                 result['data']['latestBenchmarks'].first['refId']
    assert_equal latest_benchmark.version,
                 result['data']['latestBenchmarks'].first['version']
    assert_equal latest_benchmark.os_major_version,
                 result['data']['latestBenchmarks'].first['osMajorVersion']
  end

  test 'query benchmark with rules' do
    cp = FactoryBot.create(:canonical_profile, :with_rules)

    query = <<-GRAPHQL
      query benchmarkQuery($id: String!) {
        benchmark(id: $id) {
          id
          osMajorVersion
          rules {
            id
            title
          }
        }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { id: cp.benchmark.id },
      context: { current_user: @user }
    )

    assert_equal result['data']['benchmark']['rules'].count, cp.rules.count
  end

  test 'query benchmark with rule identifiers' do
    cp = FactoryBot.create(:canonical_profile, :with_rules)

    query = <<-GRAPHQL
      query benchmarkQuery($id: String!) {
        benchmark(id: $id) {
          id
          osMajorVersion
          rules {
            id
            title
            severity
            rationale
            refId
            description
            remediationAvailable
            identifier
          }
        }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { id: cp.benchmark.id },
      context: { current_user: @user }
    )

    identifiers = result['data']['benchmark']['rules'].map { |x| x['identifier'] }
    ref = cp.rules.map { |rule| { 'label' => rule.identifier['label'], 'system' => rule.identifier['system'] } }
    assert_same_elements(identifiers, ref)
  end

  test 'ruleTree returns rules and groups in a tree structure' do
    bm = FactoryBot.create(:benchmark)

    Xccdf::Benchmark.any_instance.expects(:rule_tree).returns('foo')

    query = <<-GRAPHQL
      query benchmarkQuery($id: String!) {
        benchmark(id: $id) {
          id
          ruleTree
        }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { id: bm.id },
      context: { current_user: @user }
    )

    assert_equal result['data']['benchmark']['ruleTree'], 'foo'
  end

  test 'query benchmark with value definitions' do
    vd1 = FactoryBot.create(:value_definition, title: 'test1')
    vd2 = FactoryBot.create(:value_definition, title: 'test2')
    vd2.update!(benchmark_id: vd1.benchmark_id)

    query = <<-GRAPHQL
      query benchmarkQuery($id: String!) {
        benchmark(id: $id) {
          id
          valueDefinitions {
            id
            refId
            valueType
            title
            description
            defaultValue
          }
        }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { id: vd1.benchmark_id },
      context: { current_user: @user }
    )

    assert_equal result['data']['benchmark']['valueDefinitions'].count, 2
    assert_equal(%w[test1 test2], result['data']['benchmark']['valueDefinitions'].map do |value_definition|
      value_definition['title']
    end.sort)
  end
end
