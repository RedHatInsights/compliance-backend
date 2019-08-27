# frozen_string_literal: true

require 'prometheus_exporter/client' if Rails.env.production?

# Definition for the GraphQL schema - read the
# GraphQL-ruby documentation to find out what to add or
# remove here.
class Schema < GraphQL::Schema
  use GraphQL::Tracing::PrometheusTracing if Rails.env.production?
  query Types::Query
  mutation Types::Mutation
end
