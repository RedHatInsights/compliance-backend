# frozen_string_literal: true

module Kafka
  # Consumer concerns related to report parsing
  # rubocop:disable Metrics/ClassLength
  class ReportParser
    # Raise an error if entitlement is not available
    class EntitlementError < StandardError; end
    # Raise an error if parsing report is not possible
    class ReportParseError < StandardError; end

    def initialize(message, logger)
      @message = message
      @logger = logger
    end

    def parse_reports
      # Map successfuly parsed (validated) reports by scanned profile
      parsed_reports = downloaded_reports.map { |xml| parse(xml) }
      # Evaluate each report individually and notify about the result
      parsed_reports.each do |report|
        process_report(report.test_result_file.test_result.profile_id, report)
      end
      produce_validation_message('success')
    rescue EntitlementError, ReportParseError => e
      parse_error(e)
    rescue SafeDownloader::DownloadError => e
      parse_error(e)
      raise
    end

    private

    def downloaded_reports
      raise EntitlementError unless identity.valid?
      raise ReportParseError, 'Report empty' if reports.empty?

      reports
    end

    def notify_report_success(profile_id, job)
      msg = "Enqueued report parsing of #{profile_id} from request #{request_id} as a job #{job}"
      @logger.audit_success("[#{org_id}] #{msg}")
      notify_payload_tracker(:received, "File of #{profile_id} is valid. Job #{job} enqueued")
    end

    def notify_payload_tracker(status, status_msg = '')
      PayloadTracker.deliver(
        account: account, system_id: @message['id'],
        request_id: request_id, status: status,
        status_msg: status_msg, org_id: org_id
      )
    end

    def reports
      @reports ||= SafeDownloader.download_reports(url, ssl_only: Settings.report_download_ssl_only)
    end

    def identity
      Insights::Api::Common::IdentityHeader.new(b64_identity)
    end

    def metadata
      (@message.dig('platform_metadata', 'metadata') || {}).merge(
        'id' => id,
        'b64_identity' => b64_identity,
        'url' => url,
        'request_id' => request_id,
        'org_id' => org_id
      )
    end

    def id
      @message.dig('host', 'id')
    end

    def account
      @message.dig('host', 'account')
    end

    def b64_identity
      @message.dig('platform_metadata', 'b64_identity')
    end

    def request_id
      @message.dig('platform_metadata', 'request_id')
    end

    def org_id
      @message.dig('platform_metadata', 'org_id')
    end

    def url
      @message.dig('platform_metadata', 'url')
    end

    def parse(xml)
      XccdfReportParser.new(xml, metadata)
    rescue PG::Error, ActiveRecord::StatementInvalid => e
      parse_error(e)
    rescue StandardError
      raise ReportParseError, 'Report parsing failed'
    end

    def produce_validation_message(result)
      return if Settings.kafka.topics.upload_compliance.blank?

      ReportValidation.deliver(
        request_id: request_id,
        service: 'compliance',
        validation: result
      )
    end

    def process_report(profile, report)
      @logger.info "Processing #{profile} report #{report}"

      # Storing notification preconditions before saving the report
      should_notify = notifications_allowed?(report)

      # Evaluate compliance of the report
      if report_compliant?(report)
        report.save_all
      elsif should_notify
        @logger.info('Emitting notification due to non-compliance')
        notify_non_compliant!
      end

      notify_remediation(report)
      parse_success(report, profile)
    end

    def report_compliant?(report)
      report.supported? && report.score >= report.policy.compliance_threshold
    end

    def notifications_allowed?(report)
      previously_compliant = report.policy&.compliant?(report.system)
      no_test_results = report.policy&.test_result_systems&.where(id: report.system.id)&.empty?

      previously_compliant || no_test_results
    end

    def notify_non_compliant!(report)
      SystemNonCompliant.deliver(
        system: report.system,
        org_id: @message['org_id'],
        policy: report.policy,
        policy_threshold: report.policy.compliance_threshold,
        compliance_score: report.score
      )
    end

    def notify_remediation(report)
      RemediationUpdates.deliver(
        system_id: @message['id'],
        issue_ids: remediation_issue_ids(report)
      )
    end

    def remediation_issue_ids(report)
      report.failed_rules
            .includes(profiles: :benchmark)
            .collect(&:remediation_issue_id)
            .compact
    end

    def parse_success(report, profile)
      msg = "[#{org_id}] Successfull report of #{profile} " \
            "for policy #{report.system_profile.policy_id} " \
            "from system #{@message['id']}"
      @logger.audit_success msg
      produce_validation_message('success')
    end

    def parse_error(exception)
      msg = "[#{org_id}] #{exception_message(exception)}"
      @logger.error msg
      @logger.audit_fail msg

      ReportUploadFailed.deliver(
        system: Host.find_by(id: id, account: account),
        request_id: request_id,
        error: exception_message(exception),
        org_id: org_id
      )
      produce_validation_message('failure')
    end

    def exception_message(exception)
      case exception.class.to_s
      when 'Kafka::ReportParser::EntitlementError'
        "Rejected report with request id #{request_id}: invalid identity or missing insights entitlement"
      when 'SafeDownloader::DownloadError'
        "Failed to download report with request id #{request_id}: #{exception.message}"
      when 'Kafka::ReportParser::ReportParseError'
        "Invalid report: #{exception.message}"
      else
        "Error parsing report: #{request_id} - #{exception.message}"
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
