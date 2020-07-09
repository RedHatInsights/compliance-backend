# frozen_string_literal: true

# Job meant to delete hosts and associated objects asynchronously
class DeleteHost
  include Sidekiq::Worker
  include RecordNotFound

  def perform(message)
    Host.transaction do
      Sidekiq.logger.info("Deleting rule results for host #{message['id']}")
      RuleResult.where(host_id: message['id']).delete_all
      rescue_not_found do
        Sidekiq.logger.info("Destroying host #{message['id']}")
        Host.find_by!(id: message['id']).destroy
      end
    end
  end
end
