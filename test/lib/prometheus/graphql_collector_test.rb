# frozen_string_literal: true

require 'test_helper'
require 'prometheus_exporter/server'
require 'graphql/tracing/prometheus_tracing/graphql_collector'
require 'prometheus/graphql_collector'

class GraphQLCollectorTest < ActiveSupport::TestCase
  setup do
    @collector = GraphQLCollector.new
  end

  test 'metrics' do
    assert_nothing_raised do
      assert_not_empty @collector.metrics
    end
  end
end
