# frozen_string_literal: true

# A Kafka producer client for upload-compliance
class ReportValidation < ApplicationProducer
  TOPIC = Settings.kafka.topics.upload_compliance

  # rubocop:disable Metrics/ParameterLists
  def self.deliver(request_id:, service:, validation:)
    deliver_message(
      request_id: request_id,
      service: service,
      validation: validation
    )
  rescue *EXCEPTIONS => e
    logger.error("ReportValidation delivery failed: #{e}")
  end
  # rubocop:enable Metrics/ParameterLists
end
