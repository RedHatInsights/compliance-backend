# frozen_string_literal: true

module Mutations
  module BusinessObjective
    # Mutation to create business objectives
    class Create < BaseMutation
      graphql_name 'createBusinessObjective'

      argument :title, String, required: true
      field :business_objective, Types::BusinessObjective, null: true

      def resolve(title:)
        business_objective = ::BusinessObjective.new(title: title)
        business_objective.save
        { business_objective: business_objective }
      end
    end
  end
end
