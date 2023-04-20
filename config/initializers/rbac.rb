RBACApiClient.configure do |config|
  config.host = Settings.rbac.host
  config.scheme = Settings.rbac.scheme
  config.ssl_ca_cert = ENV['SSL_CERT_FILE'].presence
  if Settings.platform_basic_auth_username.present?
    config.username = Settings.platform_basic_auth_username
    config.password = Settings.platform_basic_auth_password
  end
end
