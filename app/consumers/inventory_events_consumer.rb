# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class InventoryEventsConsumer < ApplicationConsumer
  subscribes_to Settings.kafka_consumer_topics.inventory_events

  # Raise an error with a cause if a report isn't valid
  class ReportValidationError < StandardError; end

  include ReportParsing

  def process(message)
    super

    Insights::API::Common::AuditLog.audit_with_account(
      @msg_value['account']
    ) do
      dispatch
    end
  ensure
    clear!
  end

  def dispatch
    if service == 'compliance'
      handle_report_parsing
    elsif @msg_value['type'] == 'delete'
      handle_host_delete
    else
      logger.debug { "Skipped message of type #{@msg_value['type']}" }
    end
  end

  def handle_report_parsing
    produce(parse_report,
            topic: Settings.kafka_producer_topics.upload_validation)
  end

  def handle_host_delete
    DeleteHost.perform_async(@msg_value)
  rescue StandardError => e
    logger.audit_fail(
      "Failed to enqueue DeleteHost job for host #{@msg_value['id']}: #{e}"
    )
    raise
  else
    logger.audit_success(
      "Enqueued DeleteHost job for host #{@msg_value['id']}"
    )
  end

  # NB: This consumer object stays around between messages
  def clear!
    @report_contents, @msg_value = nil
  end
end
