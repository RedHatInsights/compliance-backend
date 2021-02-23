# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to delete a Profile
    class Delete < BaseMutation
      graphql_name 'deleteProfile'

      argument :id, ID, required: true
      field :profile, Types::Profile, null: false

      def resolve(args = {})
        profile = Pundit.authorize(
          context[:current_user],
          ::Profile.find(args[:id]),
          :destroy?
        )
        profile.destroy!
        audit_mutation(profile)
        { profile: profile }
      end

      private

      def audit_mutation(profile)
        audit_success(
          "Removed profile #{profile.id} of policy #{profile.policy_id}"
        )
      end
    end
  end
end
