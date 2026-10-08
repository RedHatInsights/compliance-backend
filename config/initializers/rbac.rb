# frozen_string_literal: true

# Required eagerly because this initializer runs before Zeitwerk activates
# the lib/ autoloader (same pattern as `require 'insights'` in application.rb).
require_relative '../../lib/clowder_v2_helpers'

unless ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)
  rbac = ClowderV2Helpers.resolve_rbac_endpoint

  RBACApiClient.configure do |config|
    config.host = rbac[:host]
    config.scheme = rbac[:scheme]
    # V2 source: use V2 CA certificate (nil = system trust when absent).
    # V1 source: preserve existing SSL_CERT_FILE behavior from the engine.
    config.ssl_ca_cert = rbac[:source] == :v2 ? rbac[:ca_certificate] : ENV['SSL_CERT_FILE'].presence
    if Settings.platform_basic_auth_username.present?
      config.username = Settings.platform_basic_auth_username
      config.password = Settings.platform_basic_auth_password
    end
  end

  # When the V2 endpoint is authenticated, Rbac must attach a service-account
  # Bearer token and X-RH-RBAC-ORG-ID header to every RBAC API call.
  Rbac.rbac_authenticated = rbac[:authenticated]
end
