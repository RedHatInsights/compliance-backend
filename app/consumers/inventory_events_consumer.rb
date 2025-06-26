# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class InventoryEventsConsumer < ApplicationConsumer
  # rubocop:disable Metrics/AbcSize
  def consume_one
    if message_type == 'delete'
      Kafka::DeletedSystemCleaner.new(payload, logger).cleanup_system
    elsif service == 'compliance'
      Kafka::ReportParser.new(payload, logger).parse_reports
    elsif policy_id && %w[created updated].include?(message_type)
      Kafka::PolicySystemImporter.new(payload, logger).import
    else
      logger.debug "Skipped message of type '#{message_type}'"
    end
  end
  # rubocop:enable Metrics/AbcSize

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

  def policy_id
    payload.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
  end
end
