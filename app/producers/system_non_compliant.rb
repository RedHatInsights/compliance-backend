# frozen_string_literal: true

# A Kafka producer client for non-compliant alerts
class SystemNonCompliant < Notification
  EVENT_TYPE = 'compliance-below-threshold'

  # rubocop:disable Metrics/MethodLength
  def self.build_events(host:, policy:, policy_threshold:, compliance_score:)
    [{
      metadata: {},
      payload: {
        host_id: host.id,
        host_name: host.display_name,
        policy_id: policy.id,
        policy_name: policy.name,
        policy_threshold: policy_threshold,
        compliance_score: compliance_score
      }
    }]
  end
  # rubocop:enable Metrics/MethodLength

  def self.build_context(host:, **_kwargs)
    {
      display_name: host.display_name,
      host_url: "https://console.redhat.com/insights/inventory/#{host.id}",
      inventory_id: host.id,
      rhel_version: [host.os_major_version, host.os_minor_version].join('.'),
      tags: host.tags
    }
  end
end
