# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class InventoryEventsConsumer < ApplicationConsumer
  NON_INSIGHTS_ID = '00000000-0000-0000-0000-000000000000'

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
    Kafka::SystemImporter.new(payload, logger).import if importable_host?
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

  def importable_host?
    insights_host? && !excluded_host_type?
  end

  def insights_host?
    insights_id = payload.dig('host', 'insights_id')
    insights_id.present? && insights_id != NON_INSIGHTS_ID
  end

  def excluded_host_type?
    profile = payload.dig('host', 'system_profile') || {}

    profile['host_type'] == 'edge' ||
      profile.dig('operating_system', 'name')&.match?(/centos/i) ||
      profile.dig('bootc_status', 'booted', 'image_digest').present?
  end

  def policy_id
    payload.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
  end
end
