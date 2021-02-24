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
        audit_mutation(business_objective)
        { business_objective: business_objective }
      end

      private

      def audit_mutation(business_objective)
        audit_success(
          "Created Business Objective #{business_objective.id}"
        )
      end
    end
  end
end
