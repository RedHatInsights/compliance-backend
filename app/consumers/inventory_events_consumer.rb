# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class InventoryEventsConsumer < ApplicationConsumer
  def consume_one
    case message_type
    when 'delete'
      Kafka::DeletedSystemCleaner.new(payload, logger).cleanup_system
    when 'created', 'updated'
      handle_created_updated
    else
      handle_other
    end
  end

  private

  def handle_created_updated
    Kafka::SystemImporter.new(payload, logger).import
    Kafka::PolicySystemImporter.new(payload, logger).import if policy_id
    Kafka::ReportParser.new(payload, logger).parse_reports if service == 'compliance'
  end

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

  def policy_id
    payload.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
  end
end
