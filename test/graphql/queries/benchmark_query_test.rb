# frozen_string_literal: true

require 'test_helper'

class BenchmarkQueryTest < ActiveSupport::TestCase
  test 'query benchmark owned by the user' do
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

    assert_equal benchmarks(:one).id,
                 result['data']['latestBenchmarks'].first['id']
    assert_equal benchmarks(:one).title,
                 result['data']['latestBenchmarks'].first['title']
    assert_equal benchmarks(:one).ref_id,
                 result['data']['latestBenchmarks'].first['refId']
    assert_equal benchmarks(:one).version,
                 result['data']['latestBenchmarks'].first['version']
  end
end
