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

      enqueue_parse_report_job
    rescue EntitlementError, SafeDownloader::DownloadError => e
      handle_report_error(e)
    end

    def enqueue_parse_report_job
      if validation_message == 'success'
        report_contents.each do |report|
          job = ParseReportJob
                .perform_async(ActiveSupport::Gzip.compress(report), metadata)
          logger.info "Message enqueued: #{request_id} as #{job}"
          notify_payload_tracker(:received,
                                 "File is valid. Job #{job} enqueued")
        end
      end

      validation_payload(request_id, validation_message)
    end

    def validation_message
      return @validation_message if @validation_message

      report_contents.each do |report|
        XccdfReportParser.new(report, metadata)
      end
      @validation_message = 'success'
    rescue StandardError => e
      logger.error "Error validating report: #{request_id}"\
        " - #{e.message}"
      @validation_message = 'failure'
    end

    private

    def handle_report_error(exc)
      error_message = msg_for_exception(exc)
      logger.error error_message
      notify_payload_tracker(:error, error_message)

      validation_payload(request_id, 'failure')
    end

    def msg_for_exception(exc)
      case exc
      when EntitlementError
        "Rejected report with request id #{request_id}:" \
        ' invalid identity or missing insights entitlement'
      when SafeDownloader::DownloadError
        "Failed to dowload report with request id #{request_id}: #{e.message}"
      else
        "Error parsing report: #{request_id} - #{e.message}"
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
        'id' => id
      )
    end

    def request_id
      @msg_value.dig('platform_metadata', 'request_id')
    end

    def b64_identity
      @msg_value.dig('platform_metadata', 'b64_identity')
    end

    def report_contents
      @report_contents ||= SafeDownloader.download(url)
    end

    def identity
      IdentityHeader.new(b64_identity)
    end
  end
end
