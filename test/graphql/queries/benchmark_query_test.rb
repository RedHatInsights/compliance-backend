# frozen_string_literal: true

require 'test_helper'

class BenchmarkQueryTest < ActiveSupport::TestCase
  test 'query benchmark owned by the user' do
    supported_ssg = SupportedSsg.new(version: '0.1.50',
                                     os_major_version: '7',
                                     os_minor_version: '3')
    SupportedSsg.stubs(:latest_per_os_major).returns([supported_ssg])

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
    assert_equal latest_benchmark.os_major_version,
                 result['data']['latestBenchmarks'].first['osMajorVersion']
  end
end
