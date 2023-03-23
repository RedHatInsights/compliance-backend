RBACApiClient.configure do |config|
  config.host = Settings.rbac_url
  config.scheme = Settings.rbac_url.split('://').first
  if Settings.platform_basic_auth_username.present?
    config.username = Settings.platform_basic_auth_username
    config.password = Settings.platform_basic_auth_password
  end
end
