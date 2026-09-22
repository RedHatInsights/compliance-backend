# frozen_string_literal: true

# Karafka configuration
class KarafkaApp < Karafka::App
  CLIENT_ID = 'compliance_backend'
  INVENTORY_EVENTS_MAX_MESSAGES_DEFAULT = 100
  INVENTORY_EVENTS_MAX_WAIT_TIME_DEFAULT = 100

  def self.inventory_events_max_messages
    ENV.fetch('KARAFKA_MAX_MESSAGES', INVENTORY_EVENTS_MAX_MESSAGES_DEFAULT).to_i
  end

  def self.inventory_events_max_wait_time
    ENV.fetch('KARAFKA_MAX_WAIT_TIME', INVENTORY_EVENTS_MAX_WAIT_TIME_DEFAULT).to_i
  end

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
    config.concurrency = ENV.fetch('KARAFKA_CONCURRENCY', 4).to_i
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
        max_messages KarafkaApp.inventory_events_max_messages
        max_wait_time KarafkaApp.inventory_events_max_wait_time
        dead_letter_queue(
          topic: Settings.kafka.topics.compliance_dlq,
          max_retries: InventoryEventsConsumer::MAX_RETRIES,
          independent: true
        )
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
