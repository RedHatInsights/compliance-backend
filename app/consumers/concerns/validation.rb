# frozen_string_literal: true

# Consumer concerns related to message validation
module Validation
  extend ActiveSupport::Concern

  included do
    def validation_payload(request_id, result)
      {
        'request_id': request_id,
        'service': 'compliance',
        'validation': result
      }.to_json
    end

    def notify_payload_tracker(status, status_msg = '')
      PayloadTracker.deliver(
        account: @msg_value['account'], system_id: @msg_value['id'],
        request_id: @msg_value['request_id'], status: status,
        status_msg: status_msg
      )
    end
  end
end
