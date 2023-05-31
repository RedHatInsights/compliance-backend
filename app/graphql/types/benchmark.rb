# frozen_string_literal: true

module Types
  # Definition of Benchmark as a GraphQL type
  class Benchmark < Types::BaseObject
    model_class ::Xccdf::Benchmark
    graphql_name 'Benchmark'
    description 'A representation of a SCAP Security Guide version'

    field :id, ID, null: false
    field :description, String, null: true
    field :title, String, null: false
    field :ref_id, String, null: false
    field :version, String, null: false
    field :os_major_version, String, null: false
    field :latest_supported_os_minor_versions, [String], null: false

    cached_static_field :profiles, [::Types::Profile], null: true
    cached_static_field :rules, [::Types::Rule], null: true
    cached_static_field :value_definitions, [::Types::ValueDefinition], null: true
    cached_static_field :rule_tree, GraphQL::Types::JSON, null: true

    enforce_rbac Rbac::COMPLIANCE_VIEWER

    def profiles
      object.profiles.canonical
    end
  end
end
