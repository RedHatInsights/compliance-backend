# frozen_string_literal: true

require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  # Error to raise if the inventory host could not be found
  class InventoryHostNotFound < StandardError; end

  ERRORS = [InventoryHostNotFound].freeze

  def initialize(account: nil, url: Settings.host_inventory_url,
                 b64_identity: account&.b64_identity)
    @url = "#{URI.parse(url)}#{Settings.path_prefix}/inventory/v1/hosts"
    @account = account
    @b64_identity = b64_identity
  end

  def host_already_in_inventory(host_id)
    response = get("/#{host_id}")
    find_results(response, host_id)
  end

  def inventory_host(host_id)
    return @inventory_host if @inventory_host.present?

    @inventory_host = host_already_in_inventory(host_id)
    raise InventoryHostNotFound if @inventory_host.blank?

    if (os_release = system_profile([host_id]).first)
      @inventory_host['os_major_version'] = os_release['os_major_version']
      @inventory_host['os_minor_version'] = os_release['os_minor_version']
    end
    @inventory_host
  end

  def system_profile(ids)
    response = get("/#{ids.join(',')}/system_profile",
                   params: { per_page: 50, page: 1 })
    response['results'].inject([]) do |acc, host|
      os_major, os_minor = find_os_release(host['system_profile'])
      acc << { 'id' => host['id'],
               'os_major_version' => os_major,
               'os_minor_version' => os_minor }
    end
  end

  def hosts
    get
  end

  private

  def get(path = '', params: {}, headers: { X_RH_IDENTITY: @b64_identity })
    JSON.parse(Platform.connection.get("#{@url}#{path}", params, headers).body)
  end

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
