# frozen_string_literal: true

# Karafka configuration
class KarafkaApp < Karafka::App
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
    'ssl.ca.location': ca_location
  }.merge(sasl_config).compact

  setup do |config|
    config.kafka = kafka_config
    config.client_id = 'compliance-backend'

    # Wait for at least 1 seconds after an error
    config.pause_timeout = 1_000

    config.consumer_persistence = !Rails.env.development?
  end

  Karafka.monitor.subscribe(
    Karafka::Instrumentation::LoggerListener.new(
      log_polling: true
    )
  )

  Karafka.producer.monitor.subscribe(
    WaterDrop::Instrumentation::LoggerListener.new(
      Karafka.logger,
      log_messages: false
    )
  )

  routes.draw do
    topic Settings.kafka.topics.inventory_events do
      consumer ComplianceConsumer
    end
  end
end
