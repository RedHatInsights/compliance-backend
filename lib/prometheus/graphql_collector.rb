# frozen_string_literal: true

require 'graphql/tracing' if $0.include?('prometheus_exporter')
require 'graphql/tracing/prometheus_tracing/graphql_collector'

class GraphQLCollector < GraphQL::Tracing::PrometheusTracing::GraphQLCollector
end
