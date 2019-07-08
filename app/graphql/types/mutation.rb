# frozen_string_literal: true

module Types
  # Mutation type for GraphQL - should contain all mutations in the app
  # as fields
  class Mutation < Types::BaseObject
    graphql_name 'Mutation'
    description 'The mutation root of this schema'

    field :updateProfile, mutation: Mutations::Profile::Edit
    field :createBusinessObjective,
          mutation: Mutations::BusinessObjective::Create
  end
end
