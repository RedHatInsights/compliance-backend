# frozen_string_literal: true

require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(id, hostname, account, url, b64_identity)
    @id = id
    @hostname = hostname
    @url = "#{URI.parse(url)}#{ENV['PATH_PREFIX']}/inventory/v1/hosts"
    @account = account
    @b64_identity = b64_identity || @account.b64_identity
  end

  def host_already_in_inventory(hostname_or_id)
    response = Platform.connection.get(
      @url, {
        hostname_or_id: hostname_or_id
      },
      X_RH_IDENTITY: @b64_identity
    )
    find_results(JSON.parse(response.body))
  end

  def create_host_in_inventory
    response = Platform.connection.post(@url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X_RH_IDENTITY'] = @b64_identity
      req.body = create_host_body
    end

    JSON.parse(response.body).dig('data')&.first&.dig('host')
  end

  def inventory_host
    @inventory_host ||= host_already_in_inventory(@id) ||
                        (@hostname && host_already_in_inventory(@hostname)) ||
                        create_host_in_inventory
  end

  private

  def find_results(body)
    body['results'].find do |host|
      host['account'] == @account.account_number && (
        host['id'] == @id ||
        host['fqdn'] == @hostname
      )
    end
  end

  def create_host_body
    [{
      'facts': [{ 'facts': { 'fqdn': @hostname }, 'namespace': 'inventory' }],
      'fqdn': @hostname,
      'display_name': @hostname,
      'account': @account.account_number
    }].to_json
  end
end
