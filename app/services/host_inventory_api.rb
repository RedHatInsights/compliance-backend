# frozen_string_literal: true

require 'faraday'
require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(account, url, b64_identity)
    @url = "#{URI.parse(url)}#{ENV['PATH_PREFIX']}/inventory/v1/hosts"
    @account = account
    @b64_identity = b64_identity
  end

  def host_already_in_inventory
    response = connection.get(@url, {}, 'X_RH_IDENTITY' => @b64_identity)
    find_one_host(JSON.parse(response.body))
  end

  def hosts_already_in_inventory(hosts)
    response = connection.get(
      "#{@url}/#{hosts.join('%2C')}", {}, 'X_RH_IDENTITY' => @b64_identity
    )
    find_results(JSON.parse(response.body), hosts)
  end

  def create_host_in_inventory
    response = connection.post(@url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X_RH_IDENTITY'] = @b64_identity
      req.body = create_host_body
    end

    JSON.parse(response.body).dig('data')&.first&.dig('host')
  end

  def sync(host)
    @host = host
    # inventory_host = host_already_in_inventory || create_host_in_inventory
    @host.id ||= SecureRandom.uuid
    # @host.id ||= inventory_host.dig('id')
    @host.save
    @host
  end

  private

  def find_one_host(body)
    body['results'].find do |host|
      host['id'] == @host.id && host['account'] == @account.account_number
    end
  end

  def find_results(body, hosts)
    inventory_ids = body['results'].map { |host| host['id'] }
    {
      found: hosts.pluck(:id) - inventory_ids,
      not_found: inventory_ids - hosts.pluck(:id)
    }
  end

  def create_host_body
    [{
      'facts': [{ 'facts': { 'fqdn': @host.name }, 'namespace': 'inventory' }],
      'fqdn': @host.name,
      'display_name': @host.name,
      'account': @account.account_number
    }].to_json
  end

  def connection
    Faraday.new do |f|
      f.response :raise_error
      f.adapter Faraday.default_adapter # this must be the last middleware
    end
  end
end
