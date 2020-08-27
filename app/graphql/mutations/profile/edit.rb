# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to edit any of the profile  attributes
    class Edit < BaseMutation
      graphql_name 'UpdateProfile'

      argument :id, ID, required: true
      argument :name, String, required: false
      argument :description, String, required: false
      argument :compliance_threshold, Float, required: false
      argument :business_objective_id, ID, required: false

      field :profile, Types::Profile, null: true

      def resolve(args = {})
        profile = authorized_profile(args)
        profile.update(args.compact)
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
