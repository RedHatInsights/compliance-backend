# frozen_string_literal: true

# Processes a delivery of inventory events in order.
# Invokes existing system jobs synchronously; those jobs retain downstream behavior.
# Failed entries are collected during the pass and re-enqueued once as a new batch.
class InventoryEventsBatchJob < ApplicationJob
  MAX_RETRIES = 2

  queue_as :inventory

  def perform(entries)
    failed_entries = entries.filter_map { |entry| process_entry(entry) }
    return if failed_entries.empty?

    enqueue_retry(failed_entries)
  end

  private

  def process_entry(entry)
    InventoryEventsProcessor.new(entry).process
    nil
  rescue StandardError => e
    retry_count = entry.fetch('retry_count', 0) + 1
    log_failure(entry, e, retry_count)
    return entry.merge('retry_count' => retry_count) if retry_count <= MAX_RETRIES

    publish_dead_letter(entry, e, retry_count)
    count_import_failure(entry, e)
    nil
  end

  def count_import_failure(entry, error)
    return unless %w[created updated].include?(entry['type']) && error.is_a?(ActiveRecord::ActiveRecordError)

    Yabeda.compliance_system_import_failures_total.increment({})
  end

  def enqueue_retry(failed_entries)
    return if self.class.perform_later(failed_entries)

    raise ActiveJob::EnqueueError, 'Failed to enqueue inventory events retry batch'
  end

  def publish_dead_letter(entry, error, retry_count)
    return if InventoryEventsDeadLetter.deliver(entry: entry, retry_count: retry_count, error: error)

    raise ActiveJob::EnqueueError, 'Failed to enqueue inventory event dead letter'
  end

  def log_failure(entry, error, retry_count)
    metadata = entry.fetch('metadata', {})
    location = "#{metadata['topic']}:#{metadata['partition']}:#{metadata['offset']}"
    outcome = retry_count <= MAX_RETRIES ? 'will retry' : 'retries exhausted'
    Rails.logger.error(
      "Failed to process inventory event #{location} (failure #{retry_count}, #{outcome}): #{error.message}"
    )
  end
end
