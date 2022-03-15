# frozen_string_literal: true

# Consumer concerns related to message validation
module Validation
  extend ActiveSupport::Concern

  included do
    def validated_reports(report_contents, metadata)
      report_contents.map do |raw_report|
        test_result = validate_report(raw_report, metadata)

        [test_result.profile_id, raw_report]
      end
    end

    def validate_report(raw_report, metadata)
      parsed = XccdfReportParser.new(raw_report, metadata)
      parsed.test_result_file.test_result
    rescue PG::Error, ActiveRecord::StatementInvalid
      raise
    rescue StandardError
      raise InventoryEventsConsumer::ReportValidationError
    end

    def validation_payload(request_id, valid:)
      {
        'request_id': request_id,
        'service': 'compliance',
        'validation': valid ? 'success' : 'failure'
      }.to_json
    end

    def notify_payload_tracker(status, status_msg = '')
      PayloadTracker.deliver(
        account: account, system_id: id,
        request_id: request_id, status: status,
        status_msg: status_msg
      )
    end
  end
end
