# frozen_string_literal: true

desc 'Remove systems in Compliance DB which are not in the inventory'
task sync_with_inventory: [:environment] do
  ::Account.includes(:hosts).find_each do |account|
    puts "Starting to review account #{account.account_number}"
    account.hosts.each do |host|
      begin
        host = ::HostInventoryAPI.new(
          host.id, account, ::Settings.host_inventory_url, account.b64_identity
        ).inventory_host
      rescue ::InventoryHostNotFound
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
