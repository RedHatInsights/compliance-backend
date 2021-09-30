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
    field :osMajorVersion, String, null: false
    field :latest_supported_os_minor_versions, [String], null: false
    field :profiles, [::Types::Profile], null: true
    field :rules, [::Types::Rule], null: true
    field :downstream_rules, [::Types::Rule], null: true
    field :downstream_profiles, [::Types::Profile], null: true

    def downstream_profiles
      object.profiles.upstream(false)
    end

    def downstream_rules
      object.rules.upstream(false)
    end

    def profiles
      object.profiles.canonical
    end
  end
end
