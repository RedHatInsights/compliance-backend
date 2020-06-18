# frozen_string_literal: true

desc <<-END_DESC
  Imports the os_release field from the system_profile stored in the Inventory.

  To contact the Inventory API, each account b64_identity will be used.

  Examples:
    # rake import_host_os_releases
END_DESC

task import_host_os_releases: :environment do
  begin
    start_time = Time.now.utc
    puts "Starting import_host_os_releases job at #{start_time}"
    ::Account.includes(:hosts).find_each do |account|
      inventory_api = HostInventoryAPI.new(
        account, ::Settings.host_inventory_url, account.b64_identity
      )
      ::Host.find_in_batches(batch_size: 50) do |hosts|
        begin
          os_releases = inventory_api.system_profile(hosts.pluck(:id))
          print "Found OS releases for account #{account.account_number}: "
          puts os_releases
          print 'Importing...'
          Host.import os_releases
          puts 'IMPORTED'
        rescue Faraday::ClientError => e
          Rails.logger.info("#{e.message} #{e.response}")
        end
      end
    end
    puts "Finishing import_host_os_releases job at #{Time.now.utc} "\
         "and last #{end_time - start_time} seconds"
  rescue StandardError => e
    ExceptionNotifier.notify_exception(e, data: OpenshiftEnvironment.summary)
  end
end
