# frozen_string_literal: true

# Updates the host according to the inventory definition
class InventoryHostUpdatedJob
  include Sidekiq::Worker
  include RecordNotFound

  def perform(message)
    return wrong_format_warning(message) unless valid_message_format(message)

    rescue_not_found do
      update_host(message)
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

  def update_host(message)
    Sidekiq.logger.info(
      "Updating host #{message['host']['id']}:"\
      "name=#{message['host']['display_name']}"\
      "os_major_version=#{os_major_version(message)}"\
      "os_minor_version=#{os_minor_version(message)}"
    )
    Host.find_by!(
      id: message['host']['id']
    ).update!(name: message['host']['display_name'])
  end

  def os_major_version(message)
    message['host']['os_release'].split('.')[0]
  end

  def os_minor_version(message)
    message['host']['os_release'].split('.')[1]
  end
end
