
if ClowderCommonRuby::Config.clowder_enabled?

  config = ClowderCommonRuby::Config.load

  # compliance-ssg
  compliance_ssg_config = config.private_dependency_endpoints&.dig('compliance-ssg', 'service')
  compliance_ssg_url = "http://#{compliance_ssg_config&.hostname}:#{compliance_ssg_config&.port}"

  # RBAC
  rbac_config = config.dependency_endpoints.dig('rbac', 'service')
  rbac_url = "http://#{rbac_config&.hostname}:#{rbac_config&.port}"

  # Inventory
  host_inventory_config = config.dependency_endpoints&.dig('host-inventory', 'service')
  host_inventory_url = "http://#{host_inventory_config&.hostname}:#{host_inventory_config&.port}"

  # Redis (in-memory db)
  redis_url = "#{config.dig('inMemoryDb', 'hostname')}:#{config.dig('inMemoryDb', 'port')}"
  redis_password = config.dig('inMemoryDb', 'password')

  # Kafka
  first_kafka_server_config = config.kafka.brokers[0]

  kafka_server_config = {
    brokers: "#{first_kafka_server_config.dig('hostname')}:#{first_kafka_server_config.dig('port')}",
    security_protocol: first_kafka_server_config.dig('authtype')
  }

  if kafka_server_config['security_protocol'] == 'sasl_ssl'
    kafkaCaFile = File.new('tmp/kafkaCa', 'wt')
    kafkaCaFile.write(first_kafka_server_config.cacert)
    kafka_server_config['ssl_ca_location'] = File.expand_path(kafkaCaFile.path)
    kafka_server_config['sasl_username'] = first_kafka_server_config.dig('sasl', 'username')
    kafka_server_config['sasl_password'] = first_kafka_server_config.dig('sasl', 'password')
  end

  clowder_config = {
    compliance_ssg_url: compliance_ssg_url,
    kafka: kafka_server_config,
    kafka_consumer_topics: {
      inventory_events: config.kafka_topics&.dig('platform.inventory.events', 'name')
    },
    kafka_producer_topics: {
      upload_validation: config.kafka_topics&.dig('platform.upload.validation', 'name'),
      payload_tracker: config.kafka_topics&.dig('platform.payload-status', 'name'),
      remediation_updates: config.kafka_topics&.dig('platform.remediation-updates.compliance', 'name')
    },
    rbac_url: rbac_url,
    redis_url: redis_url,
    redis_password: redis_password,
    host_inventory_url: host_inventory_url,
    clowder_config_enabled: true,
    prometheus_exporter_port: config&.metricsPort
  }

  Settings.add_source!(clowder_config)
  Settings.reload!
end
