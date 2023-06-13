# frozen_string_literal: true

# A Kafka producer client for payload-tracker
class RemediationUpdates < ApplicationProducer
  TOPIC = Settings.kafka_producer_topics.remediation_updates

  def self.deliver(host_id:, issue_ids:)
    deliver_message(
      host_id: host_id,
      issues: issue_ids || []
    )
  rescue *EXCEPTIONS => e
    logger.error("Failed to report updates to Remediation service: #{e}")
  end
end
