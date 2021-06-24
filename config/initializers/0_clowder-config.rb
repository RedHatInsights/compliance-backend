
if ClowderCommonRuby::Config.clowder_enabled?

  config = ClowderCommonRuby::Config.load

  # TO-DO: Refactor with a helper function (get_service_url(app_name, component)
# Blocked by https://issues.redhat.com/browse/RHCLOUD-10212
#  remediations_hostname = config.private_dependency_endpoints.remediations.service.hostname
#  remediations_port = config.private_dependency_endpoints.remediations.service.port
#  remediations_url = "#{remediations_hostname}:#{remediations_port}"

  # RBAC
  rbac_config = config.dependency_endpoints['rbac']['service']
  rbac_url = "#{rbac_config.hostname}:#{rbac_config.port}"

  # Prometheus
  prometheus_exporter_config = config.private_dependency_endpoints.dig('compliance', 'prometheus-exporter')

  # Inventory
  host_inventory_config = config.dependency_endpoints['host-inventory']['service']
  host_inventory_url = "#{host_inventory_config.hostname}:#{host_inventory_config.port}"

  # Redis (in-memory db)
  redis_url = "#{config.inMemoryDb.hostname}:#{config.inMemoryDb.port}"

  clowder_config = {
    kafka: { 
#      brokers: "#{config.kafka_servers[0]['hostname']}:#{config.kafka_servers[0]['port']}"
      brokers: config.kafka_servers,
      # Not provided by clowder, not sure which of the following should be: [:plaintext, :ssl, :sasl_plaintext, :sasl_ssl]
      security_protocol: 'plaintext'
    },
    kafka_consumer_topics: {
      inventory_events: config.kafka_topics['platform.inventory.events'].name
    },
    kafka_producer_topics: {
      upload_validation: config.kafka_topics['platform.upload.compliance'].name,
      payload_tracker: config.kafka_topics['platform.payload-status'].name,
      remediation_updates: config.kafka_topics['platform.remediations.events'].name
    },
    prometheus_exporter_host: prometheus_exporter_config&.hostname,
    prometheus_exporter_port: prometheus_exporter_config&.port,
    rbac_url: rbac_url,
    redis_url: redis_url,
# Blocked by https://issues.redhat.com/browse/RHCLOUD-10212
#    remediations_url: remediations_url,
    host_inventory_url: host_inventory_url,
    clowder_config_enabled: true
  }

  Settings.add_source!(clowder_config)
  Settings.reload!
end
