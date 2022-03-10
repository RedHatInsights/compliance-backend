RBACApiClient.configure do |config|
  config.host = Settings.rbac_url
  config.username = Settings.platform_basic_auth_username
  config.password = Settings.platform_basic_auth_password
end
