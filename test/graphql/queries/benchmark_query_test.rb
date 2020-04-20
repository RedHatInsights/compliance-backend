# frozen_string_literal: true

require 'test_helper'

class BenchmarkQueryTest < ActiveSupport::TestCase
  test 'query benchmark owned by the user' do
    latest_benchmark = ::Xccdf::Benchmark.create(
      ref_id: ::Xccdf::Benchmark::LATEST_SUPPORTED_VERSIONS.keys[0],
      version: ::Xccdf::Benchmark::LATEST_SUPPORTED_VERSIONS.values[0],
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
              profiles {
                  id
              }
          }
      }
    GRAPHQL

    users(:test).update account: accounts(:test)

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: users(:test) }
    )

    assert_equal latest_benchmark.id,
                 result['data']['latestBenchmarks'].first['id']
    assert_equal latest_benchmark.title,
                 result['data']['latestBenchmarks'].first['title']
    assert_equal latest_benchmark.ref_id,
                 result['data']['latestBenchmarks'].first['refId']
    assert_equal latest_benchmark.version,
                 result['data']['latestBenchmarks'].first['version']
  end
end
