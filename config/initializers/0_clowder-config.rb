
if ClowderCommonRuby::Config.clowder_enabled?

  config = ClowderCommonRuby::Config.load

  remediations_config = config.dependency_endpoints&.dig('remediations', 'api')
  remediations_url = "http://#{remediations_config&.hostname}:#{remediations_config&.port}"

  # compliance-ssg
  compliance_ssg_config = config.private_dependency_endpoints&.dig('compliance-ssg', 'service')
  compliance_ssg_url = "http://#{compliance_ssg_config&.hostname}:#{compliance_ssg_config&.port}"

  # RBAC
  rbac_config = config.dependency_endpoints.dig('rbac', 'service')
  rbac_url = "http://#{rbac_config&.hostname}:#{rbac_config&.port}"

  # Prometheus
  prometheus_exporter_config = config.private_dependency_endpoints&.dig('compliance', 'prometheus-exporter')

  # Inventory
  host_inventory_config = config.dependency_endpoints&.dig('host-inventory', 'service')
  host_inventory_url = "http://#{host_inventory_config&.hostname}:#{host_inventory_config&.port}"

  # Redis (in-memory db)
  redis_url = "#{config.dig('inMemoryDb', 'hostname')}:#{config.dig('inMemoryDb', 'port')}"
  redis_password = config.dig('inMemoryDb', 'password')

  clowder_config = {
    compliance_ssg_url: compliance_ssg_url,
    kafka: {
      brokers: config.dig('kafka', 'brokers')&.map { |b| "#{b&.dig('hostname')}:#{b&.dig('port')}" }.join(','),
      # Not provided by clowder, not sure which of the following should be: [:plaintext, :ssl, :sasl_plaintext, :sasl_ssl]
      security_protocol: 'plaintext'
    },
    kafka_consumer_topics: {
      inventory_events: config.kafka_topics&.dig('platform.inventory.events', 'name')
    },
    kafka_producer_topics: {
      upload_validation: config.kafka_topics&.dig('platform.upload.compliance', 'name'),
      payload_tracker: config.kafka_topics&.dig('platform.payload-status', 'name'),
      remediation_updates: config.kafka_topics&.dig('platform.remediation-updates.compliance', 'name')
    },
    prometheus_exporter_host: prometheus_exporter_config&.hostname,
    prometheus_exporter_port: prometheus_exporter_config&.port,
    rbac_url: rbac_url,
    redis_url: redis_url,
    redis_password: redis_password,
    remediations_url: remediations_url,
    host_inventory_url: host_inventory_url,
    clowder_config_enabled: true
  }

  Settings.add_source!(clowder_config)
  Settings.reload!
end
