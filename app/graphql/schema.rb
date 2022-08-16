# frozen_string_literal: true

require 'prometheus_exporter/client'
require 'compliance_timeout'
require_relative 'types/query'
require_relative 'types/mutation'

# Definition for the GraphQL schema - read the
# GraphQL-ruby documentation to find out what to add or
# remove here.
class Schema < GraphQL::Schema
  # use GraphQL::Tracing::PrometheusTracing
  use ComplianceTimeout, max_seconds: 20
  query Types::Query
  mutation Types::Mutation
  lazy_resolve(Promise, :sync)
  use GraphQL::Batch
  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  # use GraphQL::Dataloader
  disable_introspection_entry_points if Rails.env.production?

  def self.unauthorized_object(_error)
    raise GraphQL::UnauthorizedError, 'User is not authorized to access this action.'
  end
end
