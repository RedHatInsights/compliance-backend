# frozen_string_literal: true

Unleash.configure do |config|
  config.app_name = Rails.application.class.module_parent_name
  config.url = ENV['UNLEASH_URL']
  config.custom_http_headers = { 'Authorization' => ENV['UNLEASH_TOKEN'] }
  bootstrap_data = {
    version: 1,
    features: [
      {
        name: 'compliance.kessel_enabled',
        enabled: false,
        strategies: []
      }
    ]
  }.to_json

  config.bootstrap_config = Unleash::Bootstrap::Configuration.new(
    data: bootstrap_data  # Pass as JSON string, not hash
  )
end

Rails.configuration.unleash = Unleash::Client.new
Rails.logger.info "Unleash client initialized: URL=#{ENV['UNLEASH_URL']}, App=#{Rails.application.class.module_parent_name}"
