# frozen_string_literal: true

require 'faraday'
require 'uri'
require 'json'

# Interact with the Insights Host Inventory. Usually HTTP calls
# are all that's needed.
class HostInventoryAPI
  def initialize(host, user, url)
    @host = host
    @url = URI.parse(url)
    @user = user
  end

  def host_already_in_inventory
    response = Faraday.get(
      "#{@url}/api/hosts/?format=json", {}, 'X_RH_IDENTITY' => @user.to_s
    )
    body = JSON.parse(response.body)
    return nil unless body.key? 'results'

    body['results'].find do |host|
      host['display_name'] == @host.name && host['account'] == @user
    end
  rescue Faraday::ClientError => e
    Rails.logger.error e
  end

  def create_host_in_inventory
    response = Faraday.post("#{@url}/api/hosts/") do |req|
      req.headers['Content-Type'] = 'application/json'
      # Should this be base64 encoded?
      req.headers['X_RH_IDENTITY'] = @user.to_json
      req.body = create_host_body
    end
    return false unless response.success?

    JSON.parse(res.body)
  rescue Faraday::ClientError => e
    Rails.logger.error e
  end

  def import_host
    @host.save
  end

  def sync
    create_host_in_inventory unless host_already_in_inventory
    import_host
    @host
  end

  private

  def create_host_body
    {
      'canonical_facts': {},
      'display_name': @host.name,
      'account': @host.account
    }.to_json
  end
end
