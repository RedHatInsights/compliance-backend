# frozen_string_literal: true

# A Kafka producer client for non-compliant alerts
class ReportUploadFailed < Notification
  EVENT_TYPE = 'report-upload-failed'

  # rubocop:disable Metrics/MethodLength
  def self.build_events(system:, error:, request_id: nil)
    [{
      metadata: {},
      payload: {
        host_id: system&.id,
        host_name: system&.display_name,
        request_id: request_id,
        error: error
      }.to_json
    }]
  end
  # rubocop:enable Metrics/MethodLength
end
