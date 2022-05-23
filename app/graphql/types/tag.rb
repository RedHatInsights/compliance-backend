# frozen_string_literal: true

module Types
  # This type defines a host inventory tag
  class Tag < Types::BaseObject
    implements GraphQL::Relay::Node.interface

    graphql_name 'Tag'
    description 'A host inventory tag'

    field :namespace, String, null: true
    field :key, String, null: false
    field :value, String, null: true

    enforce_rbac Rbac::SYSTEM_READ
  end
end
