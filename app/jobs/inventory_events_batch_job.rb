# frozen_string_literal: true

# Dispatches inventory events sequentially while retaining per-entry metadata.
class InventoryEventsBatchJob < ApplicationJob
  queue_as :inventory

  include InventoryPartitionConcurrency

  def perform(entries, kafka_metadata)
    context = BatchContext.new
    entries.each_with_index { |entry, index| process_entry(entry, index, context) }
    enqueue_continuations(context, kafka_metadata)
  end

  private

  # Tracks failed-system work and partition-wide fallback state for one batch.
  class BatchContext
    attr_reader :blocked_by_system, :held_by_system, :held_by_partition
    attr_accessor :partition_fallback

    def initialize
      @blocked_by_system = {}
      @held_by_system = Hash.new { |held, system_id| held[system_id] = [] }
      @held_by_partition = []
      @partition_fallback = false
    end
  end

  def process_entry(entry, index, context)
    return hold_after_partition_fallback(entry, index, context) if context.partition_fallback

    process_system_entry(entry, index, context)
  end

  def hold_after_partition_fallback(entry, index, context)
    context.held_by_partition << [index, work_item(entry, 1)]
  end

  def process_system_entry(entry, index, context)
    processor = InventoryEventsProcessor.new(entry, attempt: 1)
    system_id = processor.system_id
    if context.blocked_by_system.key?(system_id)
      context.held_by_system[system_id] << [index, work_item(entry, 1)]
      return
    end

    processor.process
  rescue StandardError => e
    handle_failure(entry, index, system_id, e, context)
  end

  def handle_failure(entry, index, system_id, error, context)
    metadata = entry.fetch('metadata')
    log_failure(metadata, error)

    if system_id.present?
      context.blocked_by_system[system_id] = true
      context.held_by_system[system_id] << [index, work_item(entry, 2)]
    else
      hold_partition_from(index, entry, context)
    end
  end

  def log_failure(metadata, error)
    coordinates = "#{metadata['topic']}:#{metadata['partition']}:#{metadata['offset']}"
    Rails.logger.error("Failed to process inventory message at #{coordinates}: #{error.message}")
  end

  def hold_partition_from(index, entry, context)
    context.partition_fallback = true
    context.held_by_system.each_value { |items| context.held_by_partition.concat(items) }
    context.held_by_system.clear
    context.held_by_partition << [index, work_item(entry, 2)]
  end

  def enqueue_continuations(context, kafka_metadata)
    if context.partition_fallback
      enqueue_items(context.held_by_partition, kafka_metadata)
    else
      context.held_by_system.each_value { |items| enqueue_items(items, kafka_metadata) }
    end
  end

  def enqueue_items(items, kafka_metadata)
    InventoryEventsContinuationJob.enqueue(items.sort_by(&:first).map(&:last), kafka_metadata)
  end

  def work_item(entry, next_attempt)
    { 'entry' => entry, 'next_attempt' => next_attempt }
  end
end
