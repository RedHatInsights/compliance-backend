# frozen_string_literal: true

# Consumer concerns related to report parsing
module ReportParsing
  extend ActiveSupport::Concern

  # Raise an error if entitlement is not available
  class EntitlementError < StandardError; end

  included do
    include Validation

    def parse_report
      raise EntitlementError unless identity.valid?

      reports = validated_reports(report_contents, metadata)
      enqueue_parse_report_job(reports)
    rescue EntitlementError, SafeDownloader::DownloadError,
           InventoryEventsConsumer::ReportValidationError => e
      handle_report_error(e)
    end

    def enqueue_parse_report_job(reports)
      reports.each_with_index do |(profile_id, _report), idx|
        job = ParseReportJob.perform_async(idx, metadata)
        notify_report_success(profile_id, job)
      end

      validation_payload(request_id, valid: true)
    end

    private

    def notify_report_success(profile_id, job)
      msg = "Enqueued report parsing of #{profile_id}"
      msg += " from request #{request_id} as job #{job}"
      logger.info(msg)
      logger.audit_success(msg)

      notify_payload_tracker(:received, "File of #{profile_id} is valid. Job #{job} enqueued")
    end

    def handle_report_error(exc)
      error_message = msg_for_exception(exc)
      logger.error error_message
      logger.audit_fail error_message
      notify_payload_tracker(:error, error_message)
      notify_report_failure(exc)
      validation_payload(request_id, valid: false)
    end

    def notify_report_failure(exc)
      host = Host.find_by(id: id, account: account)

      # Do not fire a notification for a host that has been deleted
      return unless host

      ReportUploadFailed.deliver(host: host, account_number: account, org_id: org_id,
                                 request_id: request_id, error: msg_for_notification(exc))
    end

    # rubocop:disable Metrics/MethodLength
    def msg_for_exception(exc)
      case exc
      when EntitlementError
        "Rejected report with request id #{request_id}:" \
        ' invalid identity or missing insights entitlement'
      when SafeDownloader::DownloadError
        "Failed to dowload report with request id #{request_id}: #{exc.message}"
      when InventoryEventsConsumer::ReportValidationError
        "Invalid Report: #{exc.cause.message}"
      else
        "Error parsing report: #{request_id} - #{exc.message}"
      end
    end
    # rubocop:enable Metrics/MethodLength

    def msg_for_notification(exc)
      case exc
      when EntitlementError
        "Failed to parse any uploaded report from host #{id}: invalid identity of missing insights entitlement."
      when SafeDownloader::DownloadError
        "Unable to locate any uploaded report from host #{id}."
      when InventoryEventsConsumer::ReportValidationError
        "Failed to parse any uploaded report from host #{id}: invalid format."
      end
    end

    def id
      @msg_value.dig('host', 'id')
    end

    def service
      @msg_value.dig('platform_metadata', 'service')
    end

    def url
      @msg_value.dig('platform_metadata', 'url')
    end

    def metadata
      (@msg_value.dig('platform_metadata', 'metadata') || {}).merge(
        'id' => id,
        'b64_identity' => b64_identity,
        'url' => url,
        'request_id' => request_id,
        'org_id' => org_id
      )
    end

    def request_id
      @msg_value.dig('platform_metadata', 'request_id')
    end

    def b64_identity
      @msg_value.dig('platform_metadata', 'b64_identity')
    end

    def report_contents
      @report_contents ||= SafeDownloader.download_reports(
        url,
        ssl_only: Settings.report_download_ssl_only
      )
    end

    def identity
      IdentityHeader.new(b64_identity)
    end
  end
end
