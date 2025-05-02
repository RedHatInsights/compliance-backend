# frozen_string_literal: true

module Kafka
  # Service for importing a new association between a System and a Policy
  class PolicySystemImporter
    def initialize(message, logger)
      @message = message
      @logger = logger
    end

    def import
      validate_message
      V2::PolicySystem.new(policy_id: policy_id, system_id: system_id).save!
      @logger.audit_success("[#{org_id}] Imported PolicySystem for System #{system_id}")
    rescue ActiveRecord::RecordNotFound => e
      @logger.audit_fail("[#{org_id}] Failed to import PolicySystem: #{e.message}")
      raise
    end

    private

    def validate_message
      exception_msg = 'System not found' unless V2::System.exists?(system_id)
      exception_msg = 'Policy not found' unless V2::Policy.exists?(policy_id)

      raise ActiveRecord::RecordNotFound, exception_msg if exception_msg
    end

    def system_id
      @message.dig('host', 'id')
    end

    def policy_id
      @message.dig('host', 'facts', 'image_builder', 'compliance_policy_id')
    end

    def org_id
      @message.dig('host', 'org_id')
    end
  end
end