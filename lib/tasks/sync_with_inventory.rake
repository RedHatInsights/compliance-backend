# frozen_string_literal: true

require_relative '../../app/services/concerns/xccdf/hosts'

desc 'Remove systems in Compliance DB which are not in the inventory'
task sync_with_inventory: [:environment] do
  ::Account.includes(:hosts).find_each do |account|
    puts "Starting to review account #{account.account_number}"
    account.hosts.each do |host|
      begin
        host.update_from_inventory_host!(
          ::HostInventoryAPI.new(
            account, ::Settings.host_inventory_url, account.b64_identity
          ).inventory_host(host.id)
        )
      rescue Faraday::Error => e
        puts 'Inventory API error while syncing account '\
          "#{account.account_number}: System #{host.id} - #{host.name}. "
        puts e.full_message
      rescue HostInventoryAPI::InventoryHostNotFound
        print "Account #{account.account_number}: "\
          "System #{host.id} - #{host.name} not found in the inventory. "\
          'Removing it from DB...'
        ::DeleteHost.perform_async('id': host.id)
        puts 'REMOVED'
      end
    end
    puts "Done reviewing account #{account.account_number}"
  end
end
