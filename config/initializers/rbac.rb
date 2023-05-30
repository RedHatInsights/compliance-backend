RBACApiClient.configure do |config|
  config.host = Settings.endpoints.rbac.host
  config.scheme = Settings.endpoints.rbac.scheme
  config.ssl_ca_cert = ENV['SSL_CERT_FILE'].presence
  if Settings.platform_basic_auth_username.present?
    config.username = Settings.platform_basic_auth_username
    config.password = Settings.platform_basic_auth_password
  end
end
