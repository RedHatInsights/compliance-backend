# frozen_string_literal: true

Rails.application.config.after_initialize do
  next if ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)

  rbac = ClowderV2Helpers.resolve_rbac_endpoint

  RBACApiClient.configure do |config|
    config.host = rbac[:host]
    config.scheme = rbac[:scheme]
    if rbac[:source] == :v2
      config.ssl_ca_cert = rbac[:ca_certificate]
    else
      config.ssl_ca_cert = ENV['SSL_CERT_FILE'].presence
    end
    if Settings.platform_basic_auth_username.present?
      config.username = Settings.platform_basic_auth_username
      config.password = Settings.platform_basic_auth_password
    end
  end

  Rails.application.config.x.rbac_authenticated = rbac[:authenticated]
end

Rails.application.config.to_prepare do
  next if ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)

  Rbac.rbac_authenticated = Rails.application.config.x.rbac_authenticated
end
