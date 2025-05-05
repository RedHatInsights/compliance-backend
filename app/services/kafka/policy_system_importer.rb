# frozen_string_literal: true

module Kafka
  # Service for importing a new association between a System and a Policy
  class PolicySystemImporter
    def initialize(message, logger)
      @message = message
      @logger = logger
    end

    def import
      ensure_exists(V2::Policy, policy_id, 'Policy')
      ensure_exists(V2::System, system_id, 'System')

      V2::PolicySystem.create!(policy_id: policy_id, system_id: system_id)
      @logger.audit_success("[#{org_id}] Imported PolicySystem for System #{system_id}")
    end

    private

    def ensure_exists(model, id, name)
      return if model.exists?(id: id)

      @logger.audit_fail("[#{org_id}] Failed to import PolicySystem: #{name} not found")
      raise ActiveRecord::RecordNotFound, "#{name} with ID #{id} not found"
    end

    def validate_system
      return if V2::System.exists?(id: system_id)

      @logger.audit_fail("[#{org_id}] Failed to import PolicySystem: System not found")
      raise ActiveRecord::RecordNotFound
    end

    def system_id
      @message.dig('host', 'id')
    end

    def policy_id
      payload.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
    end

    def org_id
      @message.dig('host', 'org_id')
    end
  end
end
