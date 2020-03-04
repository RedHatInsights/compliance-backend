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
        host = find_hosts([args[:id]]).first
        return delete_host(host) if args[:profile_ids].empty?
        profiles = find_profiles(args[:profile_ids])
        host.update(profiles: profiles)
        { system: host }
      end

      def delete_host(host)
        DeleteHost.perform_async(id: host.id)
        { system: host }
      end

      include HostHelper
      include ProfileHelper
    end
  end
end
