# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to associate systems with a profile
    class AssociateSystems < BaseMutation
      graphql_name 'associateSystems'

      argument :id, ID, required: true
      argument :system_ids, [ID], required: true
      field :profile, Types::Profile, null: true

      def resolve(args = {})
        ::Profile.transaction do
          profile = find_profile(args[:id])
          if profile&.policy
            profile.policy.update_hosts(args[:system_ids])
            audit_mutation(profile)
          end
          { profile: profile }
        end
      end

      include HostHelper
      include ProfileHelper

      private

      def audit_mutation(profile)
        audit_success(
          "Updated system associaton of policy #{profile.policy_id}"
        )
      end
    end
  end
end
