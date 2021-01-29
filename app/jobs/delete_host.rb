# frozen_string_literal: true

# Job meant to delete hosts and associated objects asynchronously
class DeleteHost
  include Sidekiq::Worker

  def perform(message)
    Host.transaction do
      Sidekiq.logger.info("Deleting related records for host #{message['id']}")
      [RuleResult, TestResult, PolicyHost].each do |model|
        model.where(host_id: message['id']).delete_all
      end
    end
  end
end
