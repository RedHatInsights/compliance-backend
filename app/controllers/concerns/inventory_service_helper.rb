# frozen_string_literal: true

# Module to support controller integrations with the host inventory service
module InventoryServiceHelper
  extend ActiveSupport::Concern

  included do
    def add_inventory_hosts(ids)
      existing_hosts = ::Pundit.policy_scope(current_user, ::Host)
                               .where(id: ids)
      save_hosts(ids - existing_hosts.pluck(:id)) + existing_hosts
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

      host.update_from_inventory_host!(i_host)

      host
    end

    def inventory_host(id)
      ::HostInventoryApi.new(account: current_user.account).inventory_host(id)
    end
  end
end
