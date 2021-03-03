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
    Host.transaction do
      Sidekiq.logger.info("Deleting related records for host #{host_id}")
      MODELS.each do |model|
        num_removed += model.where(host_id: host_id).delete_all
      end
    end
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
