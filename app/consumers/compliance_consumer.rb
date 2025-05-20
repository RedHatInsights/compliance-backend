# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs for processing
class ComplianceConsumer < ApplicationConsumer
  private

  def payload
    JSON.parse(@message.raw_payload)
  end

  def account
    payload.dig('platform_metadata', 'account')
  end

  def org_id
    payload.dig('platform_metadata', 'org_id')
  end
end
