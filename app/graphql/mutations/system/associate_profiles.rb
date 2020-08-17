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
        host = Host.find_or_create_from_inventory(args[:id])
        external_profiles = host.profiles.where(external: true)
        internal_profiles = find_profiles(args[:profile_ids])
        host.update(profiles: internal_profiles + external_profiles)
        { system: host }
      end

      include ProfileHelper
    end
  end
end
