# frozen_string_literal: true

def build_endpoint_url(endpoint, config)
  return URI::HTTPS.build(host: endpoint&.hostname, port: endpoint&.tlsPort).to_s if config.tlsCAPath

  URI::HTTP.build(host: endpoint&.hostname, port: endpoint&.port).to_s
end

if ClowderCommonRuby::Config.clowder_enabled?

  config = ClowderCommonRuby::Config.load

  if config.tlsCAPath
    system('cat /etc/pki/tls/certs/ca-bundle.crt /cdapp/certs/service-ca.crt > /tmp/combined.crt')
    ENV['SSL_CERT_FILE'] = '/tmp/combined.crt'
  end

  # compliance-ssg
  compliance_ssg_config = config.private_dependency_endpoints&.dig('compliance-ssg', 'service')
  compliance_ssg_url = build_endpoint_url(compliance_ssg_config, config)

  # RBAC
  rbac_config = config.dependency_endpoints.dig('rbac', 'service')
  rbac_url = build_endpoint_url(rbac_config, config)

  # Inventory
  host_inventory_config = config.dependency_endpoints&.dig('host-inventory', 'service')
  host_inventory_url = build_endpoint_url(host_inventory_config, config)

  # Redis (in-memory db)
  redis_url = "#{config.dig('inMemoryDb', 'hostname')}:#{config.dig('inMemoryDb', 'port')}"
  redis_password = config.dig('inMemoryDb', 'password')

  # Kafka
  first_kafka_server_config = config.kafka.brokers[0]
  kafka_security_protocol = first_kafka_server_config&.dig('authtype')

  kafka_server_config = {
    brokers: config.dig('kafka', 'brokers')&.map { |b| "#{b&.dig('hostname')}:#{b&.dig('port')}" }.join(',')
  }

  if kafka_security_protocol
    if kafka_security_protocol == 'sasl'
      cacert = first_kafka_server_config&.dig('cacert')
      if cacert.present?
        kafka_server_config[:ssl_ca_location] = 'tmp/kafka_ca.crt'
        File.open(kafka_server_config[:ssl_ca_location], 'w') do |f|
          f.write(cacert)
        end unless File.exist?(kafka_server_config[:ssl_ca_location])
      end
      kafka_server_config[:sasl_username] = first_kafka_server_config&.dig('sasl', 'username')
      kafka_server_config[:sasl_password] = first_kafka_server_config&.dig('sasl', 'password')
      kafka_server_config[:sasl_mechanism] = first_kafka_server_config&.dig('sasl', 'saslMechanism')
      kafka_server_config[:security_protocol] = first_kafka_server_config&.dig('sasl', 'securityProtocol')
    else
      raise "Unsupported Kafka security protocol '#{kafka_security_protocol}'"
    end
  else
    kafka_server_config[:security_protocol] = 'plaintext'
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
      remediation_updates: config.kafka_topics&.dig('platform.remediation-updates.compliance', 'name'),
      notifications: config.kafka_topics&.dig('platform.notifications.ingress', 'name')
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
