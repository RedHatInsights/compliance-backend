# frozen_string_literal: true

# Saves all of the information we can parse from a Xccdf report into db
class ParseReportJob < ApplicationJob
  include Notifications

  # https://github.com/RoamingNoMaD/yabeda-activejob#custom-tags
  def yabeda_tags(_idx, message)
    { qe: OpenshiftEnvironment.qe_account?(message['org_id']) }
  end

  def perform(idx, message)
    @msg_value = message
    Rails.logger.info(
      "Parsing report for account #{@msg_value['org_id']}, " \
      "system #{@msg_value['id']}"
    )

    @file = retrieve_file(idx)

    parse_and_save_report
  end

  private

  def retrieve_file(idx)
    @file = SafeDownloader.download_reports(
      @msg_value['url'],
      ssl_only: Settings.report_download_ssl_only
    )[idx]
  rescue SafeDownloader::DownloadError => e
    handle_error(e)
  end

  def parse_and_save_report
    notify_payload_tracker(:processing, "Job #{job_id} is now processing")
    compliance_notification_wrapper { parser.save_all }
    notify_remediation
    audit_success
    notify_payload_tracker(:success, "Job #{job_id} has completed successfully")
  rescue *XccdfReportParser::ERRORS => e
    handle_error(e)
  end

  def parser
    @parser ||= XccdfReportParser.new(@file, @msg_value)
  end

  def handle_error(exc)
    msg = error_message(exc)
    msg_with_values = "#{msg} \n #{JSON.pretty_generate(@msg_value)}"
    notify_payload_tracker(:error, msg_with_values)
    ReportUploadFailed.deliver(system: V2::System.find_by(id: @msg_value['id'], org_id: @msg_value['org_id']),
                               request_id: @msg_value['request_id'], error: notification_message(exc),
                               org_id: @msg_value['org_id'])
    Rails.logger.error(msg_with_values)
    Rails.logger.audit_fail("[#{@msg_value['org_id']}] #{msg}")
  end

  def error_message(exc)
    "#{error_msg_base}: #{exc.class}: #{exc.message}"
  end

  def notification_message(exc)
    "#{error_msg_base}: #{exc.class.to_s.demodulize}"
  end

  def error_msg_base
    msg = "Failed to parse report #{report_profile_id}"
    msg += " from system #{@msg_value['id']}" if @msg_value['id'].present?
    msg
  end

  def report_profile_id
    @parser&.test_result_file&.test_result&.profile_id
  end

  def notify_payload_tracker(status, status_msg = '')
    PayloadTracker.deliver(
      account: @msg_value['account'], system_id: @msg_value['id'],
      request_id: @msg_value['request_id'], status: status,
      status_msg: status_msg, org_id: @msg_value['org_id']
    )
  end

  def notify_remediation
    RemediationUpdates.deliver(
      system_id: @msg_value['id'],
      issue_ids: remediation_issue_ids
    )
  end

  def remediation_issue_ids
    parser.failed_rules
          .with_remediation_context
          .for_profile(parser.tailored_profile)
          .filter_map(&:remediation_issue_id)
  end

  def audit_success
    Rails.logger.audit_success(
      "[#{@msg_value['org_id']}] Successful report of #{report_profile_id} " \
      "policy #{parser.policy.id} " \
      "from system #{@msg_value['id']}"
    )
  end
end
