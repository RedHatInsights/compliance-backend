# frozen_string_literal: true

# Publishes inventory events that exhausted retries to the compliance dead letter topic.
class InventoryEventsDeadLetter < ApplicationProducer
  TOPIC = Settings.kafka.topics.compliance_dlq
  MALFORMED_TYPE = 'inventory_event_processing_failed'
  EMPTY_PAYLOAD = {}.freeze

  class << self
    # Preserve validated projections; malformed retry entries cannot safely provide a type or payload.
    # Use a stable envelope for those entries so DLQ publication succeeds without forwarding unvalidated data.
    def deliver(entry:, retry_count:, error:)
      deliver_message(
        type: malformed?(entry) ? MALFORMED_TYPE : entry.fetch('type'),
        payload: malformed?(entry) ? EMPTY_PAYLOAD : entry.fetch('payload'),
        metadata: entry.fetch('metadata', {}),
        failure: {
          retry_count: retry_count,
          error_class: error.class.name,
          error_message: error.message
        }
      )
    end

    def malformed?(entry)
      !entry.key?('type') || !entry.key?('payload')
    end
  end
end
