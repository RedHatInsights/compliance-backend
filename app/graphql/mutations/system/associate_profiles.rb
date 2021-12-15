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
        policies = find_profiles(args[:profile_ids]).map(&:policy).uniq
        policies.map do |policy|
          policy.hosts << host
        end

        audit_mutation(host, policies)
        { system: host }
      end

      include HostHelper
      include ProfileHelper

      private

      def audit_mutation(host, policies)
        msg = "Associated host #{host.id} to policies "
        msg += policies.map(&:id).join(', ')
        audit_success(msg)
      end
    end
  end
end
