# frozen_string_literal: true

module Kafka
  # Service for removing a host's associations
  class HostRemover
    def initialize(message, logger)
      @message = message
      @logger = logger
    end

    def remove_host
      DeleteHost.perform_async(@message)
    rescue StandardError => e
      @logger.audit_fail("[#{org_id}] Failed to enqueue DeleteHost job for host #{id}: #{e}")
      raise
    else
      @logger.audit_success("[#{org_id}] Enqueued DeleteHost job for host #{id}")
    end

    private

    def id
      @message.dig('id')
    end

    def org_id
      @message.dig('org_id')
    end
  end
end
