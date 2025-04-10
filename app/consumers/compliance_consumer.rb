# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class ComplianceConsumer < ApplicationConsumer
  def consume_one
    if message_type == 'delete'
      Kafka::HostRemover.new(payload, logger).remove_host
    else
      logger.debug "Skipped message of type #{message_type}"
    end
  end

  private

  def payload
    JSON.parse(@message.raw_payload)
  end

  def service
    payload.dig('platform_metadata', 'service')
  end

  def message_type
    payload.dig('type')
  end
end
