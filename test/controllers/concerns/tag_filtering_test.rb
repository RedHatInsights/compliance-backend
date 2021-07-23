# frozen_string_literal: true

require 'test_helper'

class TagFilteringTest < ActiveSupport::TestCase
  class TagParserDummy
    include TagFiltering
  end

  setup do
    @parser = TagParserDummy.new
  end

  test '#parse_tags' do
    {
      %w[foo bar] => [],
      ['foo/bar'] => [
        {
          namespace: 'foo',
          key: 'bar',
          value: nil
        }
      ],
      ['foo/bar=baz%3Dar', 'foo/bar=x%3Dx%2F'] => [
        {
          namespace: 'foo',
          key: 'bar',
          value: 'baz=ar'
        },
        {
          namespace: 'foo',
          key: 'bar',
          value: 'x=x/'
        }
      ]
    }.each do |input, output|
      assert_equal @parser.parse_tags(input), output
    end
  end
end
