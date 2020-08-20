# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs
# for processing
class InventoryEventsConsumer < ApplicationConsumer
  subscribes_to Settings.platform_kafka_inventory_topic

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

    produce(parse_report, topic: Settings.platform_kafka_validation_topic)
  end

  # NB: This consumer object stays around between messages
  def clear!
    @report_contents, @validation_message, @msg_value = nil
  end
end
