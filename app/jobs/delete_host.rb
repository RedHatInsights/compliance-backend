# frozen_string_literal: true

# Job meant to delete hosts and associated objects asynchronously
class DeleteHost
  include Sidekiq::Worker

  MODELS = [RuleResult, TestResult, PolicyHost].freeze

  def perform(message)
    host_id = message['id']
    remove_related(host_id)
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
end
