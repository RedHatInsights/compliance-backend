# frozen_string_literal: true

# A Kafka producer client for notifications
class Notification < ApplicationProducer
  TOPIC = Settings.kafka.topics.notifications_ingress
  EVENT_TYPE = nil
  BUNDLE = 'rhel'
  VERSION = 'v1.1.0'

  # rubocop:disable Metrics/MethodLength
  def self.deliver(account_number:, org_id:, **kwargs)
    msg = {
      version: VERSION,
      bundle: BUNDLE,
      application: SERVICE,
      event_type: self::EVENT_TYPE,
      timestamp: DateTime.now.iso8601,
      account_id: account_number,
      org_id: org_id,
      events: build_events(**kwargs),
      context: build_context(**kwargs).to_json,
      recipients: []
    }

    kafka&.produce_async(payload: msg.to_json, topic: self::TOPIC)
  rescue WaterDrop::BaseError => e
    logger.error("Notification delivery failed: #{e}")
  end
  # rubocop:enable Metrics/MethodLength

  def self.build_context(host:, **_kwargs)
    {
      display_name: host&.display_name,
      host_url: "https://console.redhat.com/insights/inventory/#{host&.id}",
      inventory_id: host&.id,
      rhel_version: [host&.os_major_version, host&.os_minor_version].join('.'),
      tags: host&.tags
    }
  end
end
