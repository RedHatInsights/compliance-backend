Racecar.configure do |config|
  config.log_level = 'info'
  config.group_id_prefix = 'compliance'

  config.security_protocol = Settings.kafka.security_protocol
  config.ssl_ca_location = Settings.kafka.ssl_ca_location

  if Settings.kafka.security_protocol == 'sasl_ssl'
    config.sasl_username = Settings.kafka.sasl_username
    config.sasl_password = Settings.kafka.sasl_password
    config.sasl_mechanism = 'SCRAM-SHA-512'
  end
end
