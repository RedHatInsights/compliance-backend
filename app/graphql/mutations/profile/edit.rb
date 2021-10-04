# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to edit any of the profile  attributes
    class Edit < BaseMutation
      graphql_name 'UpdateProfile'

      POLICY_ATTRIBUTES = %i[description
                             compliance_threshold business_objective_id].freeze

      argument :id, ID, required: true
      argument :name, String, required: false
      argument :description, String, required: false
      argument :compliance_threshold, Float, required: false
      argument :business_objective_id, ID, required: false

      field :profile, Types::Profile, null: true

      def resolve(args = {})
        profile = authorized_profile(args)
        profile.policy.update(args.slice(*POLICY_ATTRIBUTES))
        audit_mutation(profile)
        { profile: profile }
      end

      private

      def authorized_profile(args)
        Pundit.authorize(
          context[:current_user],
          ::Profile.find(args[:id]),
          :edit?
        )
      end

      def audit_mutation(profile)
        audit_success(
          "Updated profile #{profile.id} and" \
          " its policy #{profile.policy_id}"
        )
      end
    end
  end
end
