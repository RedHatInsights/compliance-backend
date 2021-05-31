# frozen_string_literal: true

# Common Kafka producer client
# https://www.rubydoc.info/gems/ruby-kafka/Kafka/Producer
class ApplicationProducer < Kafka::Client
  BROKERS = Settings.kafka.brokers.split(',').freeze
  CLIENT_ID = 'compliance-backend'
  SERVICE = 'compliance'
  # Define TOPIC in the inherited class.
  # Example:
  #   TOPIC = 'platform.payload-status'

  class << self
    private

    def deliver_message(msg)
      msg = msg.merge(
        date: DateTime.now.iso8601,
        service: SERVICE,
        source: ENV['APPLICATION_TYPE']
      )
      kafka&.deliver_message(msg.to_json, topic: self::TOPIC)
    end

    def logger
      Rails.logger
    end

    def kafka_ca_cert
      return unless Settings.kafka.security_protocol == 'ssl'

      File.read(Settings.kafka.ssl_ca_location)
    end

    def kafka_config
      {}.tap do |config|
        config[:client_id] = self::CLIENT_ID
        config[:ssl_ca_cert] = kafka_ca_cert if kafka_ca_cert
      end
    end

    def kafka
      @kafka ||= Kafka.new(self::BROKERS, **kafka_config) if self::BROKERS.any?
    end
  end
end
