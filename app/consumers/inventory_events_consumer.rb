# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class InventoryEventsConsumer < ApplicationConsumer
  subscribes_to Settings.kafka.topics.inventory_events

  # Raise an error with a cause if a report isn't valid
  class ReportValidationError < StandardError; end

  include ReportParsing

  def process(message)
    super

    dispatch
  rescue Redis::CannotConnectError
    handle_redis_error
  rescue PG::Error, ActiveRecord::StatementInvalid
    handle_db_error
  ensure
    clear!
  end

  def dispatch
    if service == 'compliance'
      logger.error('[DBG] calling handle_report_parsing')
      handle_report_parsing
    elsif @msg_value['type'] == 'delete'
      logger.error('[DBG] calling handle_host_delete')
      handle_host_delete
    else
      logger.debug { "Skipped message of type #{@msg_value['type']}" }
    end
  end

  def handle_report_parsing
    parse_output = parse_report
    validation_topic = Settings.kafka.topics.upload_compliance

    logger.error('[DBG] calling produce with the validation_topic')
    produce(parse_output, topic: validation_topic) if validation_topic
  end

  def handle_host_delete
    DeleteHost.perform_async(@msg_value)
  rescue StandardError => e
    logger.audit_fail(
      "[#{org_id}] Failed to enqueue DeleteHost job for host #{@msg_value['id']}: #{e}"
    )
    raise
  else
    logger.audit_success(
      "[#{org_id}] Enqueued DeleteHost job for host #{@msg_value['id']}"
    )
  end

  def handle_db_error
    logger.error(
      "[#{org_id}] Database error, clearing active connection for further reconnect"
    )
    ActiveRecord::Base.clear_active_connections!
    raise
  end

  def handle_redis_error
    logger.error("[#{org_id}] Failed to connect to elasticache/redis")
    raise
  end

  # NB: This consumer object stays around between messages
  def clear!
    @report_contents, @msg_value = nil
  end

  private

  def account
    @msg_value.dig('platform_metadata', 'account')
  end

  def org_id
    @msg_value.dig('platform_metadata', 'org_id')
  end
end
