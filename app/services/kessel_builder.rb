# frozen_string_literal: true

require 'kessel-sdk'

# Utility functions to build a Kessel client from the current Settings
class KesselBuilder
  class ConfigurationError < StandardError; end
  class << self
    include Kessel::Inventory::V1beta2
    include Kessel::GRPC
    include Kessel::Auth

    def auth
      @auth ||= build_oauth_credentials
    end

    def build_client
      if Settings.kessel.insecure
        build_insecure_client
      else
        build_secure_client
      end
    rescue StandardError => e
      Rails.logger.error("Failed to build Kessel client: #{e.message}")
      raise ConfigurationError, "Failed to build Kessel client: #{e.message}"
    end

    def build_insecure_client
      KesselInventoryService::ClientBuilder.new(Settings.kessel.url).insecure.build
    end

    def build_secure_client
      builder = KesselInventoryService::ClientBuilder.new(Settings.kessel.url)

      if Settings.kessel.auth.enabled
        builder.oauth2_client_authenticated(auth)
      else
        builder.authenticated
      end

      builder.build
    end

    def build_oauth_credentials
      discovery = fetch_oidc_discovery(Settings.kessel.auth.oidc_issuer)
      new_oauth_credentials_with_token_endpoint(discovery.token_endpoint)
    end

    def new_oauth_credentials_with_token_endpoint(token_endpoint)
      OAuth2ClientCredentials.new(
        client_id: Settings.kessel.auth.client_id,
        client_secret: Settings.kessel.auth.client_secret,
        token_endpoint: token_endpoint
      )
    end
  end
end
