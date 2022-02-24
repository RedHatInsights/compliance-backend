# frozen_string_literal: true

require 'xccdf_report_parser'

# Saves all of the information we can parse from a Xccdf report into db
class ParseReportJob
  include Sidekiq::Worker

  def perform(idx, message)
    return if cancelled?

    @msg_value = message
    Sidekiq.logger.info(
      "Parsing report for account #{@msg_value['account']}, "\
      "system #{@msg_value['id']}"
    )

    @file = retrieve_file(idx)

    Rails.logger.audit_with_account(@msg_value['account']) do
      parse_and_save_report
    end
  end

  def cancelled?
    Sidekiq.redis { |c| c.exists?("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis { |c| c.setex("cancelled-#{jid}", 86_400, 1) }
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

  def notify_if_non_compliant
    # Store the old score to detect if there was a drop or there are no test results
    pre_compliant = parser.host.test_results.empty? || parser.policy.compliant?(parser.host)

    yield

    # Produce a notification if there score drop was not caused by this report
    notify! if pre_compliant && parser.score < parser.policy.compliance_threshold
  end

  def notify!
    SystemNonCompliant.deliver(
      host: parser.host,
      account_number: @msg_value['account'],
      policy: parser.policy,
      policy_threshold: parser.policy.compliance_threshold,
      compliance_score: parser.score
    )
  end

  def parse_and_save_report
    notify_payload_tracker(:processing, "Job #{jid} is now processing")
    notify_if_non_compliant { parser.save_all }
    notify_remediation
    audit_success
    notify_payload_tracker(:success, "Job #{jid} has completed successfully")
  rescue *XccdfReportParser::ERRORS => e
    handle_error(e)
  end

  def parser
    @parser ||= XccdfReportParser.new(@file, @msg_value)
  end

  def handle_error(exc)
    msg = error_message(exc)
    msg_with_values = "#{msg} - #{@msg_value.to_json}"
    notify_payload_tracker(:error, msg_with_values)
    Sidekiq.logger.error(msg_with_values)
    Rails.logger.audit_fail(msg)
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

  def audit_success
    Rails.logger.audit_success(
      "Successful report of #{report_profile_id}" \
      " policy #{parser.host_profile.policy_id}" \
      " from host #{@msg_value['id']}"
    )
  end
end
