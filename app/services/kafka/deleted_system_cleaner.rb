# frozen_string_literal: true

module Kafka
  # Service for removing records associated with a deleted system based on a kafka message
  class DeletedSystemCleaner
    def initialize(message, logger)
      @message = message
      @logger = logger

      @id = @message.dig('id')
      @org_id = @message.dig('org_id')
    end

    def cleanup_system
      num_removed = remove_related
      audit_success if num_removed.positive?
    rescue StandardError => e
      audit_fail(e)
      raise
    end

    private

    def remove_related
      [
        remove_related_test_results,
        remove_related_policy_systems
      ].sum
    end

    def remove_related_test_results
      to_remove = V2::HistoricalTestResult.where(system_id: @id)

      num_removed = to_remove.delete_all

      num_removed
    end

    def remove_related_policy_systems
      V2::PolicySystem.where(system_id: @id).delete_all
    end

    def audit_fail(error)
      @logger.audit_fail("[#{@org_id}] Failed to delete related records for System #{@id}: #{error.message}")
    end

    def audit_success
      @logger.audit_success("[#{@org_id}] Deleted related records for System #{@id}")
    end
  end
end
