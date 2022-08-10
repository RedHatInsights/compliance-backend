# frozen_string_literal: true

module Types
  # Definition of Benchmark as a GraphQL type
  class Benchmark < Types::BaseObject
    model_class ::Xccdf::Benchmark
    graphql_name 'Benchmark'
    description 'A representation of a SCAP Security Guide version'

    field :id, ID, null: false
    field :description, String, null: true
    field :foo, String, null: true
    field :title, String, null: false
    field :ref_id, String, null: false
    field :version, String, null: false
    field :osMajorVersion, String, null: false
    field :latest_supported_os_minor_versions, [String], null: false
    field :profiles, [::Types::Profile], null: true
    field :rules, [::Types::Rule], null: true, extras: [:lookahead]

    enforce_rbac Rbac::COMPLIANCE_VIEWER

    def profiles
      object.profiles.canonical
    end

    def rules(args = {})
      return object.rules unless args[:lookahead].selects?(:identifier)

      object.rules.joins_identifier # Join and preselect an 'identifier' column
    end
  end
end
