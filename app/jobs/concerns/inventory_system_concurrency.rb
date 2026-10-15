# frozen_string_literal: true

# Coordinates inventory jobs for the same system.
module InventorySystemConcurrency
  extend ActiveSupport::Concern

  included do
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "inventory-system:#{inventory_system_id}" }
    )
  end

  private

  def inventory_system_id
    message = arguments.first
    message.dig('host', 'id') || message['id']
  end
end
