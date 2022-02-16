# frozen_string_literal: true

# A Kafka producer client for notifications
class Notification < ApplicationProducer
  TOPIC = Settings.kafka_producer_topics.notifications
  BUNDLE = 'rhel'
  VERSION = 'v1.1.0'

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.deliver(event_type:, account_number:, host:, policy:, **extra)
    payload = {
      host_id: host.id,
      host_name: host.display_name,
      policy_id: policy.id,
      policy_name: policy.name
    }.merge(extra)

    msg = {
      version: VERSION,
      bundle: BUNDLE,
      application: SERVICE,
      event_type: event_type,
      timestamp: DateTime.now.iso8601,
      account_id: account_number,
      events: [{
        metadata: {},
        payload: payload
      }],
      context: {
        display_name: host.display_name,
        host_url: "https://console.redhat.com/insights/inventory/#{host.id}",
        inventory_id: host.id,
        rhel_version: [host.os_major_version, host.os_minor_version].join('.'),
        tags: host.tags
      }
    }

    kafka&.deliver_message(msg.to_json, topic: self::TOPIC)
  rescue Kafka::DeliveryFailed => e
    logger.error("Notification delivery failed: #{e}")
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
