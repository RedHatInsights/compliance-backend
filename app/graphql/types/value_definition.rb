# frozen_string_literal: true

module Types
  # Definition of the ValueDefinition GraphQL type
  class ValueDefinition < Types::BaseObject
    graphql_name 'ValueDefinition'
    description 'A representation of a Value Definition'

    field :id, ID, null: false
    field :title, String, null: true
    field :ref_id, String, null: false
    field :value_type, String, null: false
    field :description, String, null: true
    field :default_value, String, null: false

    enforce_rbac Rbac::COMPLIANCE_VIEWER
  end
end
