# frozen_string_literal: true

# Synchronizes the hosts in our database with the hosts in the Inventory API
class HostsSync
  class << self
    def mark_last_seen
      Account.find_each do |account|
        logger.info "Mark job: #{account.account_number}"
        account.hosts.where(
          'last_seen_in_inventory <= ?', 1.day.ago
        ).find_in_batches(batch_size: 100).map do |hosts|
          check_hosts_in_inventory(hosts, account)
        end
      end
    end

    def remove_disabled_hosts
      disabled_hosts = Host.where(disabled: true,
                                  last_seen_in_inventory: 1.day.ago)
      logger.info 'Sweep job: hosts about to be removed - '\
        "#{disabled_hosts.pluck(:id)}"
      RuleResult.where(host_id: disabled_hosts.pluck(:id)).destroy_all
      disabled_hosts.destroy_all
      logger.info "Sweep job: removal finished - #{disabled_hosts.pluck(:id)}"
    end

    private

    def check_hosts_in_inventory(hosts, account)
      inventory_results = HostInventoryAPI.new(
        account,
        Settings.host_inventory_url
      ).hosts_already_in_inventory(hosts)

      Host.where(id: inventory_results[:found]).each(&:mark_as_seen)
      Host.where(id: inventory_results[:not_found]).each(&:disable)
    end

    def logger
      Rails.logger
    end
  end
end
