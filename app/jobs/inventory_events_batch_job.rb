# frozen_string_literal: true

# Dispatches inventory events sequentially while retaining per-entry metadata.
class InventoryEventsBatchJob < ApplicationJob
  queue_as :inventory

  include InventoryPartitionConcurrency

  def perform(entries, kafka_metadata)
    blocked_by_system = {}
    held_by_system = Hash.new { |held, system_id| held[system_id] = [] }
    held_by_partition = []
    partition_fallback = false

    entries.each_with_index do |entry, index|
      if partition_fallback
        held_by_partition << [index, work_item(entry, 1)]
        next
      end

      system_id = nil
      begin
        processor = InventoryEventsProcessor.new(entry, attempt: 1)
        system_id = processor.system_id
        if blocked_by_system.key?(system_id)
          held_by_system[system_id] << [index, work_item(entry, 1)]
          next
        end

        processor.process
      rescue StandardError => e
        metadata = entry.fetch('metadata')
        Rails.logger.error(
          "Failed to process inventory message at #{metadata['topic']}:#{metadata['partition']}:#{metadata['offset']}: #{e.message}"
        )

        if system_id.present?
          blocked_by_system[system_id] = true
          held_by_system[system_id] << [index, work_item(entry, 2)]
        else
          partition_fallback = true
          held_by_system.each_value { |items| held_by_partition.concat(items) }
          held_by_system.clear
          held_by_partition << [index, work_item(entry, 2)]
        end
      end
    end

    if partition_fallback
      InventoryEventsContinuationJob.enqueue(held_by_partition.sort_by(&:first).map(&:last), kafka_metadata)
    else
      held_by_system.each_value do |items|
        InventoryEventsContinuationJob.enqueue(items.sort_by(&:first).map(&:last), kafka_metadata)
      end
    end
  end

  private

  def work_item(entry, next_attempt)
    { 'entry' => entry, 'next_attempt' => next_attempt }
  end
end
