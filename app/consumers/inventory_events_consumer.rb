# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class InventoryEventsConsumer < ApplicationConsumer
  NON_INSIGHTS_ID = '00000000-0000-0000-0000-000000000000'
  MAX_RETRIES = 3

  def consume_one
    case message_type
    when 'delete'
      SystemDeleteJob.perform_later(payload)
    when 'created', 'updated'
      SystemImportJob.perform_later(payload)
    else
      handle_other
    end
  end

  private

  def handle_other
    if service == 'compliance'
      Kafka::ReportParser.new(payload, logger).parse_reports
    else
      logger.debug "Skipped message of type '#{message_type}'"
    end
  end

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
