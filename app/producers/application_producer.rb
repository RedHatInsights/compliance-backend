# frozen_string_literal: true

# Common Kafka producer client
# https://www.rubydoc.info/gems/ruby-kafka/Kafka/Producer
class ApplicationProducer < Kafka::Client
  BROKERS = [ENV['KAFKAMQ']].compact.freeze
  SSL_CA_LOCATION = ENV['RACECAR_SSL_CA_LOCATION']
  SECURITY_PROTOCOL = ENV['RACECAR_SECURITY_PROTOCOL']
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
      File.read(self::SSL_CA_LOCATION) if self::SECURITY_PROTOCOL == 'ssl'
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
