# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to edit any of the profile  attributes
    class Edit < BaseMutation
      graphql_name 'UpdateProfile'

      POLICY_ATTRIBUTES = %i[name description
                             compliance_threshold business_objective_id].freeze

      argument :id, ID, required: true
      argument :name, String, required: false
      argument :description, String, required: false
      argument :compliance_threshold, Float, required: false
      argument :business_objective_id, ID, required: false

      field :profile, Types::Profile, null: true

      def resolve(args = {})
        profile = authorized_profile(args)
        profile.policy_object.update(args.slice(*POLICY_ATTRIBUTES))
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
    end
  end
end
