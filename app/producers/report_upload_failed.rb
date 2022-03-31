# frozen_string_literal: true

# A Kafka producer client for non-compliant alerts
class ReportUploadFailed < Notification
  EVENT_TYPE = 'report-upload-failed'

  # rubocop:disable Metrics/MethodLength
  def self.build_events(host:, error:, request_id: nil)
    [{
      metadata: {},
      payload: {
        host_id: host&.id,
        host_name: host&.display_name,
        request_id: request_id,
        error: error
      }.to_json
    }]
  end
  # rubocop:enable Metrics/MethodLength
end
