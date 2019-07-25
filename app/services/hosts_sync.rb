# frozen_string_literal: true

# Synchronizes the hosts in our database with the hosts in the Inventory API
class HostsSync
  class << self
    def mark_last_seen
      Account.all.each do |account|
        account.hosts.where("last_seen_in_inventory > #{1.day.ago}")
               .select(:id).find_in_batches(100).map do |hosts|
          inventory_results = HostInventoryAPI.new(
            host.account,
            Settings.host_inventory_url,
            host.account.to_identity_header
          ).hosts_already_in_inventory(hosts)

          inventory_results[:found].each do |host|
            host.last_seen_in_inventory = Time.zone.today
          end

          inventory_results[:not_found].each do |host|
            # Host is not in the inventory? Do not destroy as API could be
            # broken. Mark it as disabled so it does not show up on the UI
            # - it will be enabled only if in a future run it's in the
            #   inventory
            host.disabled = true
          end
        end
      end
    end

    def remove_disabled_hosts
      disabled_hosts = Host.where(disabled: true,
                                  last_seen_in_inventory: 1.day.ago)
      RuleResult.where(host_id: disabled_hosts.pluck(:id)).destroy_all
      disabled_hosts.destroy_all
    end
  end
end
