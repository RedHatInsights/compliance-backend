# frozen_string_literal: true

unless ActiveModel::Type::Boolean.new.cast(Settings.disable_rbac)
  rbac = Settings.v2_endpoints&.rbac&.service
  raise 'Clowder V2 dependency endpoint rbac/service is missing' unless rbac

  RBACApiClient.configure do |config|
    config.host = rbac.host
    config.scheme = rbac.scheme
    config.ssl_ca_cert = rbac.ca_certificate || ENV['SSL_CERT_FILE'].presence
  end
end
