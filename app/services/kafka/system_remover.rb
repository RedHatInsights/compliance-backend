# frozen_string_literal: true

module Kafka
  # Service for marking a KafkaSystem as soft-deleted (tombstoned) in the systems table
  class SystemRemover
    def initialize(message, logger)
      @message = message
      @logger = logger
      @id = @message.dig('id')
      @org_id = @message.dig('org_id')
    end

    # rubocop:disable Metrics/MethodLength
    def remove_system
      computed_timestamp = delete_timestamp
      # rubocop:disable Rails/SkipsModelValidations
      result = KafkaSystem.where(id: @id)
                          .where('updated IS NULL OR updated < ?', computed_timestamp)
                          .update_all(deleted_at: computed_timestamp)
      # rubocop:enable Rails/SkipsModelValidations

      if result.zero?
        @logger.info("[Kafka::SystemRemover] Ignored stale delete event or no active system found for ID #{@id}")
      else
        @logger.audit_success("[Kafka::SystemRemover] Soft-deleted system #{@id}")
      end
    rescue StandardError => e
      @logger.audit_fail("[Kafka::SystemRemover] Failed to soft-delete system #{@id}: #{e.message}")
      raise e
    end
    # rubocop:enable Metrics/MethodLength

    private

    # rubocop:disable Metrics/MethodLength
    def delete_timestamp
      timestamp_str = @message.dig('updated') || @message.dig('timestamp')
      begin
        parsed_time = Time.zone.parse(timestamp_str) if timestamp_str
        if timestamp_str && parsed_time.nil?
          @logger.warn("[Kafka::SystemRemover] Failed to parse timestamp '#{timestamp_str}' " \
                       "for system #{@id}, falling back to current time")
        end
        parsed_time || Time.current
      rescue StandardError => e
        @logger.warn("[Kafka::SystemRemover] Error parsing timestamp '#{timestamp_str}' " \
                     "for system #{@id}: #{e.message}")
        Time.current
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
