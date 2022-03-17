# frozen_string_literal: true

# Common Kafka producer client
# https://www.rubydoc.info/gems/ruby-kafka/Kafka/Producer
class ApplicationProducer < Kafka::Client
  BROKERS = Settings.kafka.brokers.split(',').freeze
  CLIENT_ID = 'compliance-backend'
  SERVICE = 'compliance'
  DATE_FORMAT = :iso8601
  # Define TOPIC in the inherited class.
  # Example:
  #   TOPIC = 'platform.payload-status'

  class << self
    private

    def deliver_message(msg)
      msg = msg.merge(
        date: DateTime.now.send(self::DATE_FORMAT),
        service: SERVICE,
        source: ENV['APPLICATION_TYPE']
      )
      kafka&.deliver_message(msg.to_json, topic: self::TOPIC)
    end

    def logger
      Rails.logger
    end

    def kafka_ca_cert
      return unless %w[ssl sasl_ssl].include?(Settings.kafka.security_protocol)

      File.read(Settings.kafka.ssl_ca_location)
    end

    def sasl_config
      return unless Settings.kafka.security_protocol == 'sasl_ssl'

      {
        sasl_scram_username: Settings.kafka.sasl_username,
        sasl_scram_password: Settings.kafka.sasl_password,
        sasl_scram_mechanism: 'sha512'
      }
    end

    def kafka_config
      {}.tap do |config|
        config[:client_id] = self::CLIENT_ID
        config[:ssl_ca_cert] = kafka_ca_cert if kafka_ca_cert

        config.merge!(sasl_config) if sasl_config
      end
    end

    def kafka
      @kafka ||= Kafka.new(self::BROKERS, **kafka_config) if self::BROKERS.any?
    end
  end
end
