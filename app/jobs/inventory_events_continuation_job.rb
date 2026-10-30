# frozen_string_literal: true

# Retries an ordered suffix of inventory events without losing unresolved work.
class InventoryEventsContinuationJob < ApplicationJob
  # An event has failed its third processing attempt.
  class AttemptsExhausted < StandardError; end

  # A continuation could not be durably enqueued; preserve the running job.
  class EnqueueError < StandardError; end

  MAX_ATTEMPTS = 3
  BACKOFF = 30.seconds

  queue_as :inventory

  include InventoryPartitionConcurrency

  def self.enqueue(work_items, kafka_metadata)
    result = set(wait: BACKOFF).perform_later(work_items, kafka_metadata)
    raise EnqueueError, 'Failed to enqueue inventory events continuation' if result.nil? || result == false

    result
  rescue EnqueueError
    raise
  rescue StandardError => e
    raise EnqueueError, 'Failed to enqueue inventory events continuation', cause: e
  end

  def perform(work_items, kafka_metadata)
    work_items.each_with_index do |work_item, index|
      entry = work_item.fetch('entry')
      next_attempt = work_item.fetch('next_attempt')

      begin
        InventoryEventsProcessor.new(entry, attempt: next_attempt).process
      rescue StandardError => e
        if next_attempt >= MAX_ATTEMPTS
          raise AttemptsExhausted, "Inventory event exhausted #{MAX_ATTEMPTS} attempts", cause: e
        end

        continuation = [
          { 'entry' => entry, 'next_attempt' => next_attempt + 1 },
          *work_items.drop(index + 1)
        ]
        self.class.enqueue(continuation, kafka_metadata)
        return
      end
    end
  end
end
