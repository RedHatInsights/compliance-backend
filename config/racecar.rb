Racecar.configure do |config|
  config.log_level = 'info'
  config.group_id_prefix = 'compliance'

  if Settings.kafka.security_protocol
    config.security_protocol = Settings.kafka.security_protocol.try(:to_sym)

    if config.security_protocol == :sasl_ssl
      config.ssl_ca_location = Settings.kafka.ssl_ca_location
      config.sasl_username = Settings.kafka.sasl_username
      config.sasl_password = Settings.kafka.sasl_password
      config.sasl_mechanism = 'SCRAM-SHA-512'
    end
  end
end
