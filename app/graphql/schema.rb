# frozen_string_literal: true

require 'prometheus_exporter/client' unless Rails.env.test?
require 'compliance_timeout'

# Definition for the GraphQL schema - read the
# GraphQL-ruby documentation to find out what to add or
# remove here.
class Schema < GraphQL::Schema
  use GraphQL::Tracing::PrometheusTracing unless Rails.env.test?
  use ComplianceTimeout, max_seconds: 20
  query Types::Query
  mutation Types::Mutation
end
