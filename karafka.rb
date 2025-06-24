# frozen_string_literal: true

# Karafka configuration
class KarafkaApp < Karafka::App
  CLIENT_ID = 'compliance_backend'

  # librdkafka config creation
  security_protocol = Settings.kafka.security_protocol.downcase

  sasl_config = if security_protocol == 'sasl_ssl'
                  {
                    'sasl.username': Settings.kafka.sasl_username,
                    'sasl.password': Settings.kafka.sasl_password,
                    'sasl.mechanism': Settings.kafka.sasl_mechanism,
                    'security.protocol': Settings.kafka.security_protocol
                  }
                else
                  {}
                end

  ca_location = Settings.kafka.ssl_ca_location if %w[ssl sasl_ssl].include?(security_protocol)

  kafka_config = {
    'bootstrap.servers': Settings.kafka.brokers,
    'client.id': self::CLIENT_ID,
    'ssl.ca.location': ca_location
  }.merge(sasl_config).compact

  setup do |config|
    config.kafka = kafka_config
    config.client_id = self::CLIENT_ID
    config.consumer_persistence = !Rails.env.development?
    config.pause_with_exponential_backoff = false
  end

  Karafka.monitor.subscribe(
    Karafka::Instrumentation::LoggerListener.new(log_polling: false)
  )

  Karafka.producer.monitor.subscribe(
    WaterDrop::Instrumentation::LoggerListener.new(
      Karafka.logger,
      log_messages: false
    )
  )

  routes.draw do
    consumer_group :'complianceinventory-events-consumer' do
      topic Settings.kafka.topics.inventory_events do
        consumer InventoryEventsConsumer
      end
    end
  end
end

require 'karafka/instrumentation/vendors/kubernetes/liveness_listener'

listener = Karafka::Instrumentation::Vendors::Kubernetes::LivenessListener.new(
  port: 3000,
  polling_ttl: 300_000,
  consuming_ttl: 60_000
)

Karafka.monitor.subscribe(listener)
