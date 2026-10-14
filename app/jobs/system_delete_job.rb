# frozen_string_literal: true

# Deletes a system and cleans up its associated data
class SystemDeleteJob < ApplicationJob
  queue_as :deletes

  include InventorySystemConcurrency

  def perform(message, _kafka_metadata)
    Kafka::SystemRemover.new(message, Rails.logger).remove_system
    Kafka::DeletedSystemCleaner.new(message, Rails.logger).cleanup_system
  end
end
