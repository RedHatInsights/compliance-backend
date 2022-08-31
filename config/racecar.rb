Racecar.configure do |config|
  config.log_level = 'info'
  config.group_id_prefix = 'compliance'

  if Settings.kafka.security_protocol
    config.security_protocol = Settings.kafka.security_protocol.try(:downcase).try(:to_sym)

    if %i[sasl_ssl ssl].include?(config.security_protocol) && Settings.kafka.ssl_ca_location
      config.ssl_ca_location = Settings.kafka.ssl_ca_location
    end

    if config.security_protocol == :sasl_ssl
      config.sasl_username = Settings.kafka.sasl_username
      config.sasl_password = Settings.kafka.sasl_password
      config.sasl_mechanism = Settings.kafka.sasl_mechanism
    end
  end
end
