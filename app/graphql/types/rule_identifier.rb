# frozen_string_literal: true

module Types
  # Definition of the RuleIdentifier type in GraphQL
  class RuleIdentifier < Types::BaseObject
    graphql_name 'RuleIdentifier'
    description 'A Rule Identifier'

    field :id, ID, null: false
    field :label, String, null: false
    field :system, String, null: false
    field :rule, ::Types::Rule, null: true
  end
end
