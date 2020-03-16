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
        profile = find_profile(args[:id])
        hosts = find_hosts(args[:system_ids])
        profile_hosts = hosts.map do |host|
          ProfileHost.new(profile_id: profile.id, host_id: host.id)
        end
        ProfileHost.import!(profile_hosts)
        { profile: profile }
      end

      include HostHelper
      include UserHelper
      include ProfileHelper
      include InventoryServiceHelper
    end
  end
end
