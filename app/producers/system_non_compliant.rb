# frozen_string_literal: true

# A Kafka producer client for non-compliant alerts
class SystemNonCompliant < Notification
  EVENT_TYPE = 'compliance-below-threshold'

  # rubocop:disable Metrics/MethodLength
  def self.build_events(host:, policy:, compliance_score:)
    [{
      metadata: {},
      payload: {
        host_id: host&.id,
        host_name: host&.display_name,
        policy_id: policy&.profile_id,
        policy_name: policy&.title,
        policy_threshold: policy&.compliance_threshold&.round(1),
        compliance_score: compliance_score&.round(1)
      }.to_json
    }]
  end
  # rubocop:enable Metrics/MethodLength
end
