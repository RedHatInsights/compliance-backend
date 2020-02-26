# frozen_string_literal: true

module Mutations
  # Helpers for user related mutations
  module UserHelper
    def current_user
      @current_user ||= context[:current_user]
    end
  end

  # Helpers for inventory service related mutations
  module InventoryServiceHelper
    include UserHelper

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

  # Helpers for host related mutations
  module HostHelper
    include UserHelper
    include InventoryServiceHelper

    def find_hosts(system_ids)
      existing_systems = ::Pundit.policy_scope(current_user, ::Host)
                                 .where(id: system_ids)
      save_hosts(system_ids - existing_systems.pluck(:id))
      existing_systems.reload
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
  end

  # Helpers for profile related mutations
  module ProfileHelper
    include UserHelper

    def find_profiles(profile_ids)
      ::Pundit.policy_scope(current_user, ::Profile)
              .where(id: profile_ids)
    end

    def find_profile(profile_id, permission: :edit?)
      ::Pundit.authorize(
        current_user,
        ::Profile.find(profile_id),
        permission
      )
    end
  end

  class BaseMutation < GraphQL::Schema::RelayClassicMutation
  end
end
