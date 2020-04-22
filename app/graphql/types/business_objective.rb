# frozen_string_literal: true

module Types
  # Definition of BusinessObjective as a GraphQL type
  class BusinessObjective < Types::BaseObject
    graphql_name 'BusinessObjective'
    description 'A Business Objective registered in Insights Compliance'

    field :id, ID, null: false, cache: true
    field :title, String, null: false, cache: true
  end
end
