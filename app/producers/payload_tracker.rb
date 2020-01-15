# frozen_string_literal: true

# A Kafka producer client for payload-tracker
# https://www.rubydoc.info/gems/ruby-kafka/Kafka/Producer
class PayloadTracker < Kafka::Client
  BROKERS = [ENV['KAFKAMQ']].compact.freeze
  CLIENT_ID = 'compliance-payload-tracker-producer'
  TOPIC = 'platform.payload-status'
  SERVICE = 'compliance'

  class << self
    def deliver(payload_id:, status:, account:, system_id:, status_msg: nil)
      kafka&.deliver_message({
        date: DateTime.now.iso8601, service: SERVICE,
        account: account, system_id: system_id,
        payload_id: payload_id, status: status,
        status_msg: status_msg
      }.to_json, topic: TOPIC)
    rescue Kafka::DeliveryFailed => e
      logger.error("Payload tracker delivery failed: #{e}")
    end

    private

    def logger
      Rails.logger
    end

    def kafka
      @kafka ||= Kafka.new(BROKERS, client_id: CLIENT_ID) if BROKERS.any?
    end
  end
end
