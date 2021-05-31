Racecar.configure do |config|
  config.log_level = 'info'
  config.group_id_prefix = 'compliance'

  config.security_protocol = Settings.kafka.security_protocol
  config.ssl_ca_location = Settings.kafka.ssl_ca_location
end
