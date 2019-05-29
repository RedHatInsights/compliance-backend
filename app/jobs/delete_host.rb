# frozen_string_literal: true

# Job meant to delete hosts and associated objects asynchronously
class DeleteHost
  include Sidekiq::Worker

  def perform(message)
    Host.transaction do
      RuleResult.where(host_id: message['id']).delete_all
      Host.find(message['id']).destroy
    end
  end
end
