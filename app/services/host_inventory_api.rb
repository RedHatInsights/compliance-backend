# frozen_string_literal: true

require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(id, account, url, b64_identity)
    @id = id
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

    @inventory_host
  end

  private

  def find_results(body)
    body['results'].find do |host|
      host['account'] == @account.account_number && host['id'] == @id
    end
  end
end
