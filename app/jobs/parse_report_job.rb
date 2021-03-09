# frozen_string_literal: true

require 'xccdf_report_parser'

# Saves all of the information we can parse from a Xccdf report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(file, message)
    return if cancelled?

    @file = file
    @msg_value = message
    Sidekiq.logger.info(
      "Parsing report for account #{@msg_value['account']}, "\
      "system #{@msg_value['id']}"
    )
    Rails.logger.audit_with_account(@msg_value['account']) do
      save_all
    end
  end

  def cancelled?
    Sidekiq.redis { |c| c.exists?("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86_400, 1) }
  end

  private

  def save_all
    notify_payload_tracker(:processing, "Job #{jid} is now processing")
    parser.save_all
    notify_remediation
    notify_payload_tracker(:success, "Job #{jid} has completed successfully")
  rescue *XccdfReportParser::ERRORS => e
    handle_error(e)
  end

  def parser
    @parser ||= XccdfReportParser.new(ActiveSupport::Gzip.decompress(@file),
                                      @msg_value)
  end

  def handle_error(exc)
    msg_with_values = "#{error_message(exc)} - #{@msg_value.to_json}"
    notify_payload_tracker(:error, msg_with_values)
    Sidekiq.logger.error(msg_with_values)
  end

  def error_message(exc)
    "#{error_msg_base}: #{exc.class}: #{exc.message}"
  end

  def error_msg_base
    msg = "Failed to parse report #{report_profile_id}"
    msg += " from host #{@msg_value['id']}" if @msg_value['id'].present?
    msg
  end

  def report_profile_id
    @parser&.test_result_file&.test_result&.profile_id
  end

  def notify_payload_tracker(status, status_msg = '')
    PayloadTracker.deliver(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: status,
      status_msg: status_msg
    )
  end

  def notify_remediation
    RemediationUpdates.deliver(
      host_id: @msg_value['id'],
      issue_ids: remediation_issue_ids
    )
  end

  def remediation_issue_ids
    parser.failed_rules
          .includes(profiles: :benchmark)
          .collect(&:remediation_issue_id)
          .compact
  end
end
