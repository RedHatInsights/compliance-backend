# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class ComplianceConsumer < ApplicationConsumer
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def consume_one
    dispatch
  rescue Redis::CannotConnectError
    handle_redis_error
  end

  def dispatch
    if service == 'compliance'
      Kafka::ReportParser.new(payload, logger).parse_reports
    elsif message_type == 'created' && image_builder?
      Kafka::PolicySystemImporter.new(payload, logger).import
    elsif message_type == 'delete'
      Kafka::HostRemover.new(payload, logger).remove_host
    else
      logger.info "Skipped message of type '#{message_type}'"
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def payload
    JSON.parse(@message.raw_payload)
  end

  def service
    payload.dig('platform_metadata', 'service')
  end

  def org_id
    payload.dig('platform_metadata', 'org_id')
  end

  def message_type
    payload.dig('type')
  end

  def image_builder?
    payload.dig('host', 'image_builder', 'compliance_policy_id').present?
  end

  def handle_redis_error
    logger.error("[#{org_id}] Failed to connect to elasticache/redis")
    raise
  end
end