# frozen_string_literal: true

module Types
  # Definition of BusinessObjective as a GraphQL type
  class BusinessObjective < Types::BaseObject
    graphql_name 'BusinessObjective'
    description 'A Business Objective registered in Insights Compliance'

    field :id, ID, null: false
    field :title, String, null: false

    enforce_rbac Rbac::POLICY_READ
  end
end
