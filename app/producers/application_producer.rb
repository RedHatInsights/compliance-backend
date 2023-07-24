# frozen_string_literal: true

require 'rdkafka'

# Common Kafka producer client
class ApplicationProducer
  BROKERS = Settings.kafka.brokers.split(',').freeze
  EXCEPTIONS = [Rdkafka::RdkafkaError, Rdkafka::AbstractHandle::WaitTimeoutError].freeze
  CLIENT_ID = 'compliance-backend'
  SERVICE = 'compliance'
  DATE_FORMAT = :iso8601
  # Define TOPIC in the inherited class.
  # Example:
  #   TOPIC = 'platform.payload-status'

  class << self
    def ping
      # The partition count method fails if the connection is not alive, so we are
      # sending a random topic name to it for status checks.
      kafka.partition_count(Settings.kafka.topics.to_h.values.compact.sample)
    end

    private

    def deliver_message(msg)
      msg = msg.merge(
        date: DateTime.now.utc.send(self::DATE_FORMAT),
        service: SERVICE,
        source: ENV['APPLICATION_TYPE']
      )
      kafka&.produce(payload: msg.to_json, topic: self::TOPIC)&.wait
    end

    def logger
      Rails.logger
    end

    def kafka_ca_cert
      return unless %w[ssl sasl_ssl].include?(Settings.kafka.security_protocol.downcase)

      Settings.kafka.ssl_ca_location
    end

    def sasl_config
      return {} unless Settings.kafka.security_protocol.downcase == 'sasl_ssl'

      {
        'sasl.username' => Settings.kafka.sasl_username,
        'sasl.password' => Settings.kafka.sasl_password,
        'sasl.mechanism' => Settings.kafka.sasl_mechanism,
        'security.protocol' => Settings.kafka.security_protocol
      }
    end

    def kafka_config
      {
        'bootstrap.servers' => Settings.kafka.brokers,
        'client.id' => self::CLIENT_ID,
        'ssl.ca.location' => kafka_ca_cert
      }.merge(sasl_config).compact
    end

    def kafka
      @kafka ||= Rdkafka::Config.new(kafka_config).producer if self::BROKERS.any?
    end
  end
end
