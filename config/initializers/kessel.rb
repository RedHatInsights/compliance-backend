# frozen_string_literal: true

# Kessel configuration initializer
# This initializer sets up Kessel configuration from environment variables
# and validates the configuration when Kessel is enabled.

Rails.application.configure do
  # Override settings from environment variables
  if ENV['KESSEL_ENABLED'].present?
    Settings.kessel.enabled = ActiveModel::Type::Boolean.new.cast(ENV['KESSEL_ENABLED'])
  end

  if ENV['KESSEL_URL'].present?
    Settings.kessel.url = ENV['KESSEL_URL']
  end

  if ENV['KESSEL_AUTH_ENABLED'].present?
    Settings.kessel.auth.enabled = ActiveModel::Type::Boolean.new.cast(ENV['KESSEL_AUTH_ENABLED'])
  end

  if ENV['KESSEL_AUTH_CLIENT_ID'].present?
    Settings.kessel.auth.client_id = ENV['KESSEL_AUTH_CLIENT_ID']
  end

  if ENV['KESSEL_AUTH_CLIENT_SECRET'].present?
    Settings.kessel.auth.client_secret = ENV['KESSEL_AUTH_CLIENT_SECRET']
  end

  if ENV['KESSEL_AUTH_OIDC_ISSUER'].present?
    Settings.kessel.auth.oidc_issuer = ENV['KESSEL_AUTH_OIDC_ISSUER']
  end

  if ENV['KESSEL_INSECURE'].present?
    Settings.kessel.insecure = ActiveModel::Type::Boolean.new.cast(ENV['KESSEL_INSECURE'])
  end

  if ENV["KESSEL_PRINCIPAL_DOMAIN"].present?
    Settings.kessel.principal_domain = ENV['KESSEL_PRINCIPAL_DOMAIN']
  end

  if ENV['KESSEL_GROUPS_TEMP_TABLE_THRESHOLD'].present?
    Settings.kessel.groups_temp_table_threshold = ENV['KESSEL_GROUPS_TEMP_TABLE_THRESHOLD'].to_i
  elsif Settings.kessel.groups_temp_table_threshold.nil?
    Settings.kessel.groups_temp_table_threshold = 50
  end

  # Validate Kessel configuration when enabled
  if Settings.kessel.enabled
    Rails.logger.info 'Kessel is enabled, validating configuration...'

    if Settings.kessel.url.blank?
      raise 'KESSEL_URL must be set when Kessel is enabled'
    end

    unless Settings.kessel.auth.enabled
      raise 'KESSEL_AUTH_ENABLED must be set when Kessel is enabled'
    end

    if Settings.kessel.auth.enabled
      if Settings.kessel.auth.client_id.blank?
        raise 'KESSEL_AUTH_CLIENT_ID must be set when Kessel auth is enabled'
      end

      if Settings.kessel.auth.client_secret.blank?
        raise 'KESSEL_AUTH_CLIENT_SECRET must be set when Kessel auth is enabled'
      end

      if Settings.kessel.auth.oidc_issuer.blank?
        raise 'KESSEL_AUTH_OIDC_ISSUER must be set when Kessel auth is enabled'
      end
    end

    Rails.logger.info "Kessel configured: URL=#{Settings.kessel.url}, Auth=#{Settings.kessel.auth.enabled}"
  else
    Rails.logger.info 'Kessel is disabled, using RBAC v1'
  end
end
