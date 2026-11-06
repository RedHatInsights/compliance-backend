# frozen_string_literal: true

# Processes a delivery of inventory events in order.
# Invokes existing system jobs synchronously; those jobs retain downstream behavior.
class InventoryEventsBatchJob < ApplicationJob
  queue_as :inventory

  MAX_ATTEMPTS = 3

  class BatchEntryError < StandardError; end

  retry_on BatchEntryError, wait: :polynomially_longer, attempts: MAX_ATTEMPTS

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def perform(entries, attempt = 1)
    failed_entries = []
    first_error = nil

    entries.each do |entry|
      InventoryEventsProcessor.new(entry, attempt: attempt).process
    rescue StandardError => e
      failed_entries << entry
      first_error ||= e
      log_failure(entry, e)
    end

    return if failed_entries.empty?

    self.arguments = [failed_entries, attempt + 1]
    raise BatchEntryError, first_error.message, first_error.backtrace
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def log_failure(entry, error)
    metadata = entry.fetch('metadata', {})
    location = "#{metadata['topic']}:#{metadata['partition']}:#{metadata['offset']}"
    Rails.logger.error("Failed to process inventory event #{location}: #{error.message}")
  end
end
