# frozen_string_literal: true

module Types
  # This type defines a host operating system
  class OperatingSystem < GraphQL::Types::Relay::BaseObject
    graphql_name 'OperatingSystem'
    description 'An operating system with its version'

    field :name, String, null: false
    field :major, Int, null: false
    field :minor, Int, null: false
  end
end
