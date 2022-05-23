# frozen_string_literal: true

module Types
  # This type defines a host operating system
  class OperatingSystem < Types::BaseObject
    graphql_name 'OperatingSystem'
    description 'An operating system with its version'

    field :name, String, null: false
    field :major, Int, null: false
    field :minor, Int, null: false

    enforce_rbac Rbac::COMPLIANCE_VIEWER
  end
end
