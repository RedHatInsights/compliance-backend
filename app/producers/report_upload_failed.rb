# frozen_string_literal: true

# A Kafka producer client for non-compliant alerts
class ReportUploadFailed < Notification
  EVENT_TYPE = 'report-upload-failed'

  # rubocop:disable Metrics/MethodLength
  def self.build_events(host:, error:)
    [{
      metadata: {},
      payload: {
        host_id: host&.id,
        host_name: host&.display_name,
        error: error
      }
    }]
  end
  # rubocop:enable Metrics/MethodLength
end
