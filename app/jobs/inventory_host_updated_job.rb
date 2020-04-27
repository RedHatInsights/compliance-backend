# frozen_string_literal: true

# Updates the host according to the inventory definition
class InventoryHostUpdatedJob
  include Sidekiq::Worker
  include RecordNotFound

  def perform(message)
    if message['host'] && message['host']['display_name']
      rescue_not_found do
        Host.find_by!(
          id: message['host']['id']
        )&.update(name: message['host']['display_name'])
      end
    else
      wrong_format_warning(message)
    end
  end

  def wrong_format_warning(message)
    Sidekiq.logger.warn(
      'Received a message to update a hostname but message '\
      "doesn't have the expected format - #{message}"
    )
  end
end
