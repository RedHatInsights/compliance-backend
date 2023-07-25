# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to associate systems with a profile
    class AssociateSystems < BaseMutation
      graphql_name 'associateSystems'

      argument :id, ID, required: true
      argument :system_ids, [ID], required: true
      field :profile, Types::Profile, null: true
      field :profiles, [Types::Profile], null: true

      enforce_rbac Rbac::POLICY_WRITE

      def resolve(args = {})
        ::Profile.transaction do
          hosts = find_hosts(args[:system_ids])
          profile = find_profile(args[:id])
          if profile&.policy
            profile.policy.update_hosts(hosts.pluck(:id), current_user)
            audit_mutation(profile)
          end
          { profile: profile, profiles: profile.policy.profiles }
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
