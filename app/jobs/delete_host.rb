# frozen_string_literal: true

# Job meant to delete hosts and associated objects asynchronously
class DeleteHost
  include Sidekiq::Worker

  MODELS = [RuleResult, TestResult, PolicyHost].freeze

  def perform(message)
    Rails.logger.audit_with_account(message['account']) do
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
    num_removed = 0
    profiles_to_rescore = []
    Sidekiq.logger.info("Deleting related records for host #{host_id}")
    MODELS.each do |model|
      to_remove = model.where(host_id: host_id)
      # Mark profile IDs as to be rescored if the model is TestResult
      profiles_to_rescore = to_remove.pluck(:profile_id) if model == TestResult
      num_removed += to_remove.delete_all
    end

    # Rescore all marked profiles in batches
    Profile.where(id: profiles_to_rescore.uniq).find_each(&:calculate_score!)

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
