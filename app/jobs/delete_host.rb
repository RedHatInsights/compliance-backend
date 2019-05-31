# frozen_string_literal: true

# Job meant to delete hosts and associated objects asynchronously
class DeleteHost
  include Sidekiq::Worker

  def perform(message)
    Host.transaction do
      RuleResult.where(host_id: message['id']).delete_all
      Host.find(message['id']).destroy
    end

  rescue ActiveRecord::RecordNotFound => error
    Sidekiq.logger.info(
      "#{error.message} (#{error.class}) "\
      "- this host ID was not registered in Compliance"
    )
  end
end
