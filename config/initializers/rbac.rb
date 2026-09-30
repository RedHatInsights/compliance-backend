# frozen_string_literal: true

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
end
