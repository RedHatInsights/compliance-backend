# frozen_string_literal: true

module Types
  # Definition of the Profile type in GraphQL
  class TestResult < Types::BaseObject
    model_class ::TestResult
    graphql_name 'TestResult'
    description 'A TestResult as recorded in Insights Compliance'

    field :id, ID, null: false, cache: true
    field :start_time, String, null: true, cache: true
    field :end_time, String, null: false, cache: true
    field :score, Float, null: false, cache: true
    field :profile, ::Types::Profile, null: false, cache: true
    field :host, ::Types::System, null: false, cache: true
  end
end
