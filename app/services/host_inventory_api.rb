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

  def host_already_in_inventory(id)
    response = Platform.connection.get(
      "#{@url}/#{id}", {}, X_RH_IDENTITY: @b64_identity
    )
    find_results(JSON.parse(response.body))
  end

  def inventory_host
    return @inventory_host if @inventory_host.present?

    @inventory_host = host_already_in_inventory(@id)
    raise ::InventoryHostNotFound if @inventory_host.blank?
    if (os_release = host_os_releases([@id]).first)
      @inventory_host.os_major = os_major
      @inventory_host.os_minor = os_minor
    end
    @inventory_host
  end

  def host_os_releases(ids)
    response = Platform.connection.get(
      "#{@url}/#{ids.join(',')}/system_profile", { per_page: 50, page: 1 },
      X_RH_IDENTITY: @b64_identity
    )
    os_releases = []
    response.body['results'].each do |host|
      os_major, os_minor = host['system_profile']['os_release'].split('.')
      os_releases << { id: host['id'],
                       os_major: os_major,
                       os_minor: os_minor }
    end
    os_releases
  end

  def import_os_releases(ids)
    os_releases = host_os_releases(ids)
    Host.import os_releases
  end

  private

  def find_results(body)
    body['results'].find do |host|
      host['account'] == @account.account_number && host['id'] == @id
    end
  end
end
