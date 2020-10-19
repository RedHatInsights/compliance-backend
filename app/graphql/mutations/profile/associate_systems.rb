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
        add_inventory_hosts(args[:system_ids])
        profile&.policy_object&.update_hosts(args[:system_ids])
        { profile: profile }
      end

      include HostHelper
      include ProfileHelper
    end
  end
end
