# frozen_string_literal: true

require 'test_helper'
require 'query_parser'

class QueryParserTest < ActiveSupport::TestCase
  setup do
    @parser = Insights::API::Common::QueryParser.new(
      Rack::Utils.default_query_parser
    )
  end

  test '#parse_nested_query' do
    {
      'foo=bar' => { foo: 'bar' },
      'tags=foo&tags=bar' => { tags: [] },
      'tags=foo/bar' => {
        tags: [
          {
            namespace: 'foo',
            key: 'bar',
            value: nil
          }
        ]
      },
      'tags=foo/bar=baz%3Dar&tags=foo/bar=x%3Dx&x=y&z' => {
        tags: [
          {
            namespace: 'foo',
            key: 'bar',
            value: 'baz=ar'
          },
          {
            namespace: 'foo',
            key: 'bar',
            value: 'x=x'
          }
        ],
        x: 'y',
        z: nil
      }
    }.each do |input, output|
      assert_equal @parser.parse_nested_query(input, '&').symbolize_keys, output
    end
  end
end
