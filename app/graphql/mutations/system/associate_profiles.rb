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
        host = Host.find(args[:id])
        policies = find_profiles(args[:profile_ids]).map(&:policy_object).uniq
        policies.map do |policy|
          policy.hosts << host
        end

        { system: host }
      end

      include HostHelper
      include ProfileHelper
    end
  end
end
