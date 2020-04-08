# frozen_string_literal: true

desc 'Remove systems in Compliance DB which are not in the inventory'
task sync_with_inventory: [:environment] do
  Account.all.find_each do |account|
    puts "Starting to review account #{account.account_number}"
    account.hosts.find_each do |host|
      begin
        host = HostInventoryAPI.new(
          host.id, account, ::Settings.host_inventory_url, account.b64_identity
        ).inventory_host
      rescue ::InventoryHostNotFound
        print "Account #{account.account_number}: "\
          "System #{host.id} - #{host.name} not found in the inventory. "\
          'Removing it from DB...'
        host.destroy!
        puts 'REMOVED'
      rescue ActiveRecord::RecordNotDestroyed => e
        puts "Errors that prevented destruction: #{e.record.errors}"
      end
    end
    puts "Done reviewing account #{account.account_number}"
  end
end
