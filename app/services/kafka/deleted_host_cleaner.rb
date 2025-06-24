# frozen_string_literal: true

module Kafka
  # Service for removing a host's associations
  class DeletedHostCleaner
    def initialize(message, logger)
      @message = message
      @logger = logger

      @id = @message.dig('id')
      @org_id = @message.dig('org_id')
    end

    def cleanup_host
      num_removed = remove_related
      audit_success(num_removed) if num_removed.positive?
    rescue StandardError => e
      audit_fail(e)
      raise
    end

    private

    def remove_related
      [
        remove_related_rule_results,
        remove_related_test_results,
        remove_related_policy_hosts
      ].sum
    end

    def remove_related_rule_results
      RuleResult.where(host_id: @id).delete_all
    end

    def remove_related_test_results
      to_remove = TestResult.where(host_id: @id)
      profiles_to_adjust = Profile.where(id: to_remove.pluck(:profile_id).uniq)

      num_removed = to_remove.delete_all

      profiles_to_adjust.find_each do |profile|
        profile.calculate_score!
        profile.policy.update_counters!
      end

      num_removed
    end

    def remove_related_policy_hosts
      to_remove = PolicyHost.where(host_id: @id)
      policies_to_adjust = Policy.where(id: to_remove.pluck(:policy_id).uniq)

      num_removed = to_remove.delete_all

      policies_to_adjust.find_each(&:update_counters!)

      num_removed
    end

    def audit_fail(error)
      @logger.audit_fail("[#{@org_id}] Failed to delete related records for Host #{@id}: #{error.message}")
    end

    def audit_success(num_removed)
      @logger.audit_success("[#{@org_id}] Deleted #{num_removed} related records for Host #{@id}")
    end
  end
end
