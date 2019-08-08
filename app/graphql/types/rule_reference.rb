# frozen_string_literal: true

module Types
  # Definition of the RuleReference type in GraphQL
  class RuleReference < Types::BaseObject
    graphql_name 'RuleReference'
    description 'An OpenSCAP Rule Reference'

    field :id, ID, null: false
    field :label, String, null: false
    field :href, String, null: false
    field :rules, [::Types::Rule], null: true
  end
end
