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

      private

      def find_profile(profile_id)
        ::Pundit.authorize(
          current_user,
          ::Profile.find(profile_id),
          :edit?
        )
      end

      def find_hosts(system_ids)
        existing_systems = ::Pundit.policy_scope(current_user, ::Host)
                                   .where(id: system_ids)
        save_hosts(system_ids - existing_systems.pluck(:id))
        existing_systems
      end

      def save_hosts(ids)
        ids.map do |id|
          save_host(id)
        end
      end

      def save_host(id)
        i_host = inventory_host(id)
        host = ::Host.find_or_initialize_by(
          id: i_host['id'],
          account_id: current_user.account.id
        )

        host.update!(
          name: i_host['fqdn']
        )

        host
      end

      def current_user
        @current_user ||= context[:current_user]
      end

      def inventory_host(id)
        ::HostInventoryAPI.new(
          id,
          nil, # unknown hostname
          current_user.account,
          ::Settings.host_inventory_url,
          nil # infer identity from account
        ).inventory_host
      end
    end
  end
end
