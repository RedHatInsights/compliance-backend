# frozen_string_literal: true

# A Kafka producer client for payload-tracker
class PayloadTracker < ApplicationProducer
  TOPIC = 'platform.payload-status'

  def self.deliver(request_id:, status:, account:, system_id:, status_msg: nil)
    # Inventory ID and system ID are identical because we match
    # system and inventory UUIDs in our database
    deliver_message(
      request_id: request_id,
      status: status,
      account: account,
      system_id: system_id,
      status_msg: status_msg
    )
  rescue Kafka::DeliveryFailed => e
    logger.error("Payload tracker delivery failed: #{e}")
  end
end
