# frozen_string_literal: true

require 'xccdf_report_parser'

# Saves all of the information we can parse from a Xccdf report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(file, message)
    return if cancelled?

    @file = file
    @msg_value = message
    save_all
  end

  def cancelled?
    Sidekiq.redis { |c| c.exists("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86_400, 1) }
  end

  private

  def save_all
    notify_payload_tracker(:processing, "Job #{jid} is now processing")
    parser.save_all
    notify_payload_tracker(:success, "Job #{jid} has completed successfully")
  rescue ::MissingIdError, ::WrongFormatError, ::InventoryHostNotFound => e
    error_message = "Cannot parse report: #{e} - #{@msg_value.to_json}"
    notify_payload_tracker(:error, error_message)
    Sidekiq.logger.error(error_message)
  end

  def parser
    @parser ||= XccdfReportParser.new(ActiveSupport::Gzip.decompress(@file),
                                      @msg_value)
  end

  def notify_payload_tracker(status, status_msg = '')
    PayloadTracker.deliver(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: status,
      status_msg: status_msg
    )
  end
end
