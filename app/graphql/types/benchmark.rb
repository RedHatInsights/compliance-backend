# frozen_string_literal: true

module Types
  # Definition of Benchmark as a GraphQL type
  class Benchmark < Types::BaseObject
    graphql_name 'Benchmark'
    description 'A representation of a SCAP Security Guide version'

    field :id, ID, null: false, cache: true
    field :description, String, null: true, cache: true
    field :title, String, null: false, cache: true
    field :ref_id, String, null: false, cache: true
    field :version, String, null: false, cache: true
    field :profiles, [::Types::Profile], null: true, cache: true
    field :rules, [::Types::Rule], null: true, cache: true

    def profiles
      object.profiles.canonical
    end
  end
end
