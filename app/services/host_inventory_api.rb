# frozen_string_literal: true

require 'uri'
require 'json'

# Error to raise if the OS release contains an invalid major or minor
class InventoryInvalidOsRelease < StandardError; end

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(account, url, b64_identity)
    @url = "#{URI.parse(url)}#{ENV['PATH_PREFIX']}/inventory/v1/hosts"
    @account = account
    @b64_identity = b64_identity || @account.b64_identity
  end

  def host_already_in_inventory(host_id)
    response = Platform.connection.get(
      "#{@url}/#{host_id}", {}, X_RH_IDENTITY: @b64_identity
    )
    find_results(JSON.parse(response.body), host_id)
  end

  def inventory_host(host_id)
    return @inventory_host if @inventory_host.present?

    @inventory_host = host_already_in_inventory(host_id)
    raise ::InventoryHostNotFound if @inventory_host.blank?

    if (os_release = system_profile([host_id]).first)
      @inventory_host[:os_major_version] = os_release[:os_major_version]
      @inventory_host[:os_minor_version] = os_release[:os_minor_version]
    end
    @inventory_host
  end

  def system_profile(ids)
    response = Platform.connection.get(
      "#{@url}/#{ids.join(',')}/system_profile", { per_page: 50, page: 1 },
      X_RH_IDENTITY: @b64_identity
    )
    JSON.parse(response.body)['results'].inject([]) do |acc, host|
      os_major, os_minor = find_os_release(host['system_profile'])
      acc << { id: host['id'],
               os_major_version: os_major,
               os_minor_version: os_minor }
    end
  end

  private

  def find_os_release(system_profile)
    return [nil, nil] if system_profile['os_release'].blank?

    system_profile['os_release'].split('.')
  end

  def find_results(body, host_id)
    body['results'].find do |host|
      host['account'] == @account.account_number && host['id'] == host_id
    end
  end
end
