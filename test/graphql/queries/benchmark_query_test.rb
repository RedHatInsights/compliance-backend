# frozen_string_literal: true

require 'test_helper'

class BenchmarkQueryTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
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

  test 'query downstream rules and profiles' do
    query = <<-GRAPHQL
      query Benchmarks {
        benchmarks {
          nodes {
            id
            profiles: downstreamProfiles {
              id
            }
            rules: downstreamRules {
              id
            }
          }
        }
      }
    GRAPHQL

    d_profile, _u_profile = FactoryBot.create_list(
      :canonical_profile,
      2,
      :with_rules,
      rule_count: 2,
      benchmark: FactoryBot.create(:benchmark)
    )

    d_rule = d_profile.rules.first
    d_profile.update!(upstream: false)
    d_rule.update!(upstream: false)

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: @user }
    )

    nodes = result.dig('data', 'benchmarks', 'nodes')

    assert_equal 1, nodes.count
    assert_equal d_profile.id, nodes.first['profiles'].first['id']
    assert_equal d_rule.id, nodes.first['rules'].first['id']
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
end
