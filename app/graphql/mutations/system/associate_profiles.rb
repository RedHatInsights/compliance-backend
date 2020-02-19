# frozen_string_literal: true

module Mutations
  module System
    # Mutation to associate profiles to a system
    class AssociateProfiles < BaseMutation
      graphql_name 'associateProfiles'

      argument :id, ID, required: true
      argument :profile_ids, [ID], required: true
      field :system, ::Types::System, null: true

      def resolve(args = {})
        host = find_host(args[:id])
        profiles = find_profiles(args[:profile_ids])
        host.update(profiles: profiles)
        { system: host }
      end

      private

      def find_host(host_id)
        ::Pundit.authorize(
          context[:current_user],
          ::Host.find(host_id),
          :edit?
        )
      end

      def find_profiles(profile_ids)
        ::Pundit.policy_scope(context[:current_user], ::Profile)
                .where(id: profile_ids)
      end
    end
  end
end
