# frozen_string_literal: true

module Kafka
  # Service for importing a new association between a System and a Policy
  class PolicySystemImporter
    def initialize(message, logger)
      @logger = logger
      @message = message

      @policy_id = message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
      @system_id = message.dig('host', 'id')
      @org_id = message.dig('host', 'org_id')
      @msg_type = message.dig('type')
      @request_id = message.dig('platform_metadata', 'request_id')
    end

    def import
      return unless sources_exist?

      policy_system = V2::PolicySystem.new(policy_id: @policy_id, system_id: @system_id, request_id: @request_id)

      if policy_system.save
        @logger.audit_success("[#{@org_id}] Imported PolicySystem for System #{@system_id} from #{@msg_type} message")
      else
        audit_fail(policy_system.errors.full_messages.join(', ').to_s)
      end
    end

    private

    def sources_exist?
      validate_resource(V2::System, @system_id, 'System', raise_on_missing: true) &&
        validate_resource(V2::Policy, @policy_id, 'Policy')
    end

    def validate_resource(model_class, id, resource_name, raise_on_missing: false)
      return true if model_class.exists?(id: id)

      audit_fail("#{resource_name} not found with ID #{id}")
      raise ActiveRecord::RecordNotFound if raise_on_missing

      false
    end

    def audit_fail(message)
      @logger.audit_fail("[#{@org_id}] Failed to import PolicySystem: #{message}")
    end
  end
end
