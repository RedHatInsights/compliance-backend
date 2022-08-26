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
    field :profiles, [::Types::Profile], null: true
    field :rules, [::Types::Rule], null: true, extras: [:lookahead]

    enforce_rbac Rbac::COMPLIANCE_VIEWER

    def profiles
      object.profiles.canonical
    end

    def rules(args = {})
      scopes = []
      scopes << :with_references if args[:lookahead].selects?(:references)
      scopes << :with_identifier if args[:lookahead].selects?(:identifier)

      ::CollectionLoader.for(object.class, :rules, *scopes).load(object)
      # {
      #   references: :with_references,
      #   identifier: :with_identifier
      # }.inject(object.rules) do |model, (selects, scope)|
      #   args[:lookahead].selects?(selects) ? model.send(scope) : model
      # end.select('rules.*')
    end
  end
end
