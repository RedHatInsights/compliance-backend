# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class InventoryEventsConsumer < ApplicationConsumer
  subscribes_to Settings.kafka_consumer_topics.inventory_events

  include ReportParsing

  def process(message)
    super(message)

    handle_report_parsing

    case @msg_value['type']
    when 'delete'
      DeleteHost.perform_async(@msg_value)
    when 'updated'
      InventoryHostUpdatedJob.perform_async(@msg_value)
    end

    clear!
  end

  def handle_report_parsing
    return unless service == 'compliance'

    produce(parse_report,
            topic: Settings.kafka_producer_topics.upload_validation)
  end

  # NB: This consumer object stays around between messages
  def clear!
    @report_contents, @validation_message, @msg_value = nil
  end
end
