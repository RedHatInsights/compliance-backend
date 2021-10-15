# frozen_string_literal: true

require 'graphql/tracing'
require 'graphql/tracing/prometheus_tracing/graphql_collector'

class GraphQLCollector < GraphQL::Tracing::PrometheusTracing::GraphQLCollector
end
