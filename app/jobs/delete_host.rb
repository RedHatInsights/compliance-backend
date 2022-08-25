# frozen_string_literal: true

# Job meant to delete hosts and associated objects asynchronously
class DeleteHost
  include Sidekiq::Worker

  MODELS = [RuleResult, TestResult, PolicyHost].freeze

  def perform(message)
    Rails.logger.audit_with_account(message['org_id']) do
      host_id = message['id']
      begin
        num_removed = remove_related(host_id)
      rescue StandardError => e
        audit_fail(host_id, e)
        raise
      end
      audit_success(host_id) if num_removed.positive?
    end
  end

  private

  def remove_related(host_id)
    Sidekiq.logger.info("Deleting related records for host #{host_id}")

    [
      remove_related_rule_results(host_id),
      remove_related_test_results(host_id),
      remove_related_policy_hosts(host_id)
    ].sum
  end

  def remove_related_rule_results(host_id)
    RuleResult.where(host_id: host_id).delete_all
  end

  def remove_related_test_results(host_id)
    to_remove = TestResult.where(host_id: host_id)
    profiles_to_adjust = Profile.where(id: to_remove.pluck(:profile_id).uniq)

    num_removed = to_remove.delete_all

    profiles_to_adjust.find_each do |profile|
      profile.calculate_score!
      profile.policy.update_counters!
    end

    num_removed
  end

  def remove_related_policy_hosts(host_id)
    to_remove = PolicyHost.where(host_id: host_id)
    policies_to_adjust = Policy.where(id: to_remove.pluck(:policy_id).uniq)

    num_removed = to_remove.delete_all

    policies_to_adjust.find_each(&:update_counters!)

    num_removed
  end

  def audit_success(host_id)
    Rails.logger.audit_success(
      "Deleteted related records for host #{host_id}"
    )
  end

  def audit_fail(host_id, exc)
    Rails.logger.audit_fail(
      "Failed to delete related records for host #{host_id}: #{exc}"
    )
  end
end
