# frozen_string_literal: true

require 'faraday'
require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(host, account, url, b64_identity)
    @host = host
    @url = "#{URI.parse(url)}/#{ENV['PATH_PREFIX']}/inventory/v1/hosts"
    @account = account
    @b64_identity = b64_identity
  end

  def host_already_in_inventory
    response = connection.get(@url, {}, 'X_RH_IDENTITY' => @b64_identity)
    body = JSON.parse(response.body)

    body['results'].find do |host|
      (host['id'] == @host.id || host['fqdn'] == @host.name) &&
        host['account'] == @account.account_number
    end
  end

  def create_host_in_inventory
    response = connection.post(@url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X_RH_IDENTITY'] = @b64_identity
      req.body = create_host_body
    end

    JSON.parse(response.body).dig('data')&.first&.dig('host')
  end

  def sync
    unless host_already_in_inventory
      new_host = create_host_in_inventory
      @host.id = new_host.dig('id')
      @host.save
    end
    @host
  end

  private

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
