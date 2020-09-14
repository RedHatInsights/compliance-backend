# frozen_string_literal: true

# Common Kafka producer client
# https://www.rubydoc.info/gems/ruby-kafka/Kafka/Producer
class ApplicationProducer < Kafka::Client
  BROKERS = [ENV['KAFKAMQ']].compact.freeze
  CLIENT_ID = 'compliance-payload-tracker-producer'
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

    def kafka
      @kafka ||= Kafka.new(BROKERS, client_id: CLIENT_ID) if BROKERS.any?
    end
  end
end
