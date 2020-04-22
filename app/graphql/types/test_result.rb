# frozen_string_literal: true

module Types
  # Definition of the Profile type in GraphQL
  class TestResult < Types::BaseObject
    model_class ::TestResult
    graphql_name 'TestResult'
    description 'A TestResult as recorded in Insights Compliance'

    field :id, ID, null: false
    field :start_time, String, null: true
    field :end_time, String, null: false
    field :score, Float, null: false
    field :profile, ::Types::Profile, null: false
    field :host, ::Types::System, null: false
  end
end
