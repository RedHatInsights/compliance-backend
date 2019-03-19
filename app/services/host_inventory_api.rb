# frozen_string_literal: true

require 'faraday'
require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(host, account, url, b64_identity)
    @host = host
    @url = "#{URI.parse(url)}/r/insights/platform/inventory/api/v1/hosts"
    @account = account
    @b64_identity = b64_identity
  end

  def host_already_in_inventory
    response = Faraday.get(@url, {}, 'X_RH_IDENTITY' => @b64_identity)
    body = JSON.parse(response.body)
    return nil unless body.key? 'results'

    body['results'].find do |host|
      host['id'] == @host.id && host['account'] == @account.account_number
    end
  rescue Faraday::ClientError => e
    Rails.logger.error e
  end

  def create_host_in_inventory
    response = Faraday.post(@url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['X_RH_IDENTITY'] = @b64_identity
      req.body = create_host_body
    end
    return false unless response.success?

    JSON.parse(response.body).dig('data')&.first&.dig('host')
  rescue Faraday::ClientError => e
    Rails.logger.error e
  end

  def sync
    unless host_already_in_inventory
      new_host = create_host_in_inventory
      @host.id = new_host['id']
    end
    @host.save
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
end
