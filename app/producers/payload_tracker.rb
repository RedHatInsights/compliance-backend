# frozen_string_literal: true

# A Kafka producer client for payload-tracker
class PayloadTracker < ApplicationProducer
  TOPIC = Settings.kafka_producer_topics.payload_tracker
  DATE_FORMAT = :rfc3339

  # rubocop:disable Metrics/ParameterLists
  def self.deliver(request_id:, status:, account:, org_id:, system_id:, status_msg: nil)
    # Inventory ID and system ID are identical because we match
    # system and inventory UUIDs in our database
    deliver_message(
      request_id: request_id,
      status: status,
      account: account,
      org_id: org_id,
      system_id: system_id,
      status_msg: status_msg
    )
  rescue *EXCEPTIONS => e
    logger.error("Payload tracker delivery failed: #{e}")
  end
  # rubocop:enable Metrics/ParameterLists
end
