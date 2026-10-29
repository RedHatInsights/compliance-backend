# frozen_string_literal: true

# Dispatches inventory events sequentially while retaining per-entry metadata.
class InventoryEventsBatchJob < ApplicationJob
  queue_as :inventory

  include InventoryPartitionConcurrency

  def perform(entries, _kafka_metadata)
    entries.each do |entry|
      dispatch(entry.fetch('type'), entry.fetch('payload'), entry.fetch('metadata'))
    rescue StandardError => e
      metadata = entry.fetch('metadata')
      Rails.logger.error(
        "Failed to process inventory message at #{metadata['topic']}:#{metadata['partition']}:#{metadata['offset']}: #{e.message}"
      )
    end
  end

  private

  def dispatch(type, payload, metadata)
    case type
    when 'delete'
      SystemDeleteJob.new(payload, metadata).perform_now
    when 'created', 'updated'
      SystemImportJob.new(payload, metadata).perform_now
    else
      if payload.dig('platform_metadata', 'service') == 'compliance'
        Kafka::ReportParser.new(payload, Rails.logger).parse_reports
      else
        Rails.logger.debug "Skipped message of type '#{type}'"
      end
    end
  end
end
