# frozen_string_literal: true

require 'prometheus_exporter/client' unless Rails.env.test? || Rails.env.development?
require 'compliance_timeout'
require_relative 'types/query'
require_relative 'types/mutation'

# Definition for the GraphQL schema - read the
# GraphQL-ruby documentation to find out what to add or
# remove here.
class Schema < GraphQL::Schema
  use GraphQL::Tracing::PrometheusTracing unless Rails.env.test? || Rails.env.development?
  use ComplianceTimeout, max_seconds: 20
  query Types::Query
  mutation Types::Mutation
  lazy_resolve(Promise, :sync)
  use GraphQL::Batch
end
