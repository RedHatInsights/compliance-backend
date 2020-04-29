# frozen_string_literal: true

# Updates the host according to the inventory definition
class InventoryHostUpdatedJob
  include Sidekiq::Worker
  include RecordNotFound

  def perform(message)
    return wrong_format_warning(message) unless valid_message_format(message)

    rescue_not_found do
      Host.find_by!(
        id: message['host']['id']
      ).update(name: message['host']['display_name'])
    end
  end

  def valid_message_format(message)
    message.dig('host', 'display_name') && message.dig('host', 'id')
  end

  def wrong_format_warning(message)
    Sidekiq.logger.warn(
      'Received a message to update a hostname but message '\
      "doesn't have the expected format - #{message}"
    )
  end
end
