# frozen_string_literal: true

module Kafka
  # Consumer concerns related to report parsing
  # rubocop:disable Rails/Output
  # rubocop:disable Metrics/ClassLength
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
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
      raise EntitlementError unless identity.valid?
      raise ReportParseError if reports.empty?

      # Map successfuly parsed (validated) reports by scanned profile
      parsed_reports = reports.map do |xml|
        [parse(xml).test_result_file.test_result.profile_id, xml]
      end

      # Evaluate each report individually and notify abut the result
      parsed_reports.each_with_index do |(profile_id, _report), idx|
        job = ParseReportJob.perform_async(idx, metadata)
        notify_report_success(profile_id, job)
        # TODO: replace with `process_report(profile_id, report)`
        #       to get rid of Sidekiq
      end

      produce_validation_message('success')
    rescue EntitlementError, ReportParseError, SafeDownloader::DownloadError => e
      puts "\n\u001b[31;1m◉\u001b[0m app/services/kafka/report_parser.rb#parse_reports"
      puts "failure: #{e}"
      puts '-' * 40
      produce_validation_message('failure')
      raise
    end

    private

    def notify_report_success(profile_id, job)
      msg = "Enqueued report parsing of #{profile_id} from request #{request_id} as job #{job}"
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
    rescue SafeDownloader::DownloadError => e
      puts "\n\u001b[31;1m◉\u001b[0m app/services/kafka/report_parser.rb#reports"
      puts "SafeDownloader => e: #{e}"
      puts '-' * 40
      parse_error(e)
      raise
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

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def parse(xml)
      puts "\n\u001b[31;1m◉\u001b[0m app/services/kafka/report_parser.rb#parse"
      puts "metadata: #{metadata}"
      puts '-' * 40
      XccdfReportParser.new(xml, metadata)
    rescue PG::Error, ActiveRecord::StatementInvalid => e
      puts "\n\u001b[31;1m◉\u001b[0m app/services/kafka/report_parser.rb#parse"
      puts "PG | ActiveRecord => e: #{e}"
      puts '-' * 40
      parse_error(e)
    rescue StandardError => e
      puts "\n\u001b[31;1m◉\u001b[0m app/services/kafka/report_parser.rb#parse"
      puts "StandardError => e: #{e}"
      puts '-' * 40
      raise ReportParseError
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def produce_validation_message(result)
      return if Settings.kafka.topics.upload_compliance.blank?

      ReportValidation.deliver(
        request_id: request_id,
        service: 'compliance',
        validation: result
      )
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def parse_error(exception)
      msg = "[#{org_id}] #{exception_message(exception)}"
      @logger.error msg
      puts "\n\u001b[31;1m◉\u001b[0m app/services/kafka/report_parser.rb#parse_error"
      puts "msg: #{msg}"
      puts '-' * 40
      @logger.audit_fail msg

      ReportUploadFailed.deliver(
        host: Host.find_by(id: id, account: account),
        request_id: request_id,
        error: exception_message(exception),
        org_id: org_id
      )
      produce_validation_message('failed')
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def exception_message(exception)
      case exception
      when EntitlementError
        "Rejected report with request id #{request_id}: invalid identity or missing insights entitlement"
      when SafeDownloader::DownloadError
        "Failed to dowload report with request id #{request_id}: #{exception.message}"
      when ReportParseError
        "Invalid report: #{exception.cause.message}"
      else
        "Error parsing report: #{request_id} - #{exception.message}"
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  # rubocop:enable Metrics/ClassLength
  # rubocop:enable Rails/Output
end