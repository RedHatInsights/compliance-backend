# frozen_string_literal: true

require 'faraday'
require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(account, url = Settings.host_inventory_url)
    @url = "#{URI.parse(url)}#{ENV['PATH_PREFIX']}/inventory/v1/hosts"
    @account = account
    @b64_identity = Base64.strict_encode64(account.to_identity_header.to_json)
  end

  def hosts_already_in_inventory(hosts)
    response = connection.get(
      "#{@url}/#{hosts.map(&:id).join('%2C')}", {},
      'X_RH_IDENTITY' => @b64_identity
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
    inventory_host = hosts_already_in_inventory([host])[:found].present? ||
                     create_host_in_inventory
    # @host.id ||= SecureRandom.uuid
    @host.id ||= inventory_host.dig('id')
    @host.save
    @host
  end

  private

  def find_results(body, hosts)
    inventory_ids = body['results'].map { |host| host['id'] }
    {
      found: inventory_ids - hosts.pluck(:id),
      not_found: hosts.pluck(:id) - inventory_ids
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
