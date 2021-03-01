# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class InventoryEventsConsumer < ApplicationConsumer
  subscribes_to Settings.kafka_consumer_topics.inventory_events

  include ReportParsing

  def process(message)
    super

    if service == 'compliance'
      handle_report_parsing
    elsif @msg_value['type'] == 'delete'
      DeleteHost.perform_async(@msg_value)
    else
      logger.debug { "Skipped message of type #{@msg_value['type']}" }
    end
  ensure
    clear!
  end

  def handle_report_parsing
    produce(parse_report,
            topic: Settings.kafka_producer_topics.upload_validation)
  end

  # NB: This consumer object stays around between messages
  def clear!
    @report_contents, @validation_message, @msg_value = nil
  end
end
