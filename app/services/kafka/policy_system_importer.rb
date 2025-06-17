# frozen_string_literal: true

module Kafka
  # Service for importing a new association between a System and a Policy
  class PolicySystemImporter
    def initialize(message, logger)
      @logger = logger

      @policy_id = message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
      @system_id = message.dig('host', 'id')
      @org_id = message.dig('host', 'org_id')
    end

    def import
      if V2::PolicySystem.exists?(policy_id: @policy_id, system_id: @system_id)
        @logger.info("[#{@org_id}] PolicySystem for System #{@system_id} already exists")
        return
      end

      ensure_exists(V2::Policy, @policy_id, 'Policy')
      ensure_exists(V2::System, @system_id, 'System')

      V2::PolicySystem.new(policy_id: @policy_id, system_id: @system_id).save!
      @logger.audit_success("[#{@org_id}] Imported PolicySystem for System #{@system_id}")
    end

    private

    def ensure_exists(model, id, name)
      return if model.exists?(id: id)

      @logger.audit_fail("[#{@org_id}] Failed to import PolicySystem: #{name} not found with ID #{id}")
      raise ActiveRecord::RecordNotFound
    end
  end
end
