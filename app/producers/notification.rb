# frozen_string_literal: true

# A Kafka producer client for notifications
class Notification < ApplicationProducer
  TOPIC = Settings.kafka_producer_topics.notifications
  EVENT_TYPE = nil
  BUNDLE = 'rhel'
  VERSION = 'v1.1.0'

  # rubocop:disable Metrics/MethodLength
  def self.deliver(account_number:, **kwargs)
    msg = {
      version: VERSION,
      bundle: BUNDLE,
      application: SERVICE,
      event_type: self::EVENT_TYPE,
      timestamp: DateTime.now.iso8601,
      account_id: account_number,
      events: build_events(**kwargs),
      context: build_context(**kwargs)
    }

    kafka&.deliver_message(msg.to_json, topic: self::TOPIC)
  rescue Kafka::DeliveryFailed => e
    logger.error("Notification delivery failed: #{e}")
  end
  # rubocop:enable Metrics/MethodLength
end
