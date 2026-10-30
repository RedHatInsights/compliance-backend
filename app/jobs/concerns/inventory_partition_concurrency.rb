# frozen_string_literal: true

# Coordinates inventory jobs for the same topic partition.
module InventoryPartitionConcurrency
  extend ActiveSupport::Concern

  included do
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { inventory_partition_key }
    )
  end

  private

  def inventory_partition_key
    metadata = arguments.last
    "inventory-partition:#{metadata.fetch('topic')}:#{metadata.fetch('partition')}"
  end
end
