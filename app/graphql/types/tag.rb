# frozen_string_literal: true

module Types
  # This type defines a host inventory tag
  class Tag < GraphQL::Types::Relay::BaseObject
    implements GraphQL::Relay::Node.interface

    graphql_name 'Tag'
    description 'A host inventory tag'

    field :namespace, String, null: false
    field :key, String, null: false
    field :value, String, null: true
  end
end
