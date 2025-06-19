# frozen_string_literal: true

module Kafka
  # Service for importing a new association between a System and a Policy
  class PolicySystemImporter
    MODELS = [V2::Policy, V2::System].freeze

    def initialize(message, logger)
      @logger = logger

      @policy_id = message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')
      @system_id = message.dig('host', 'id')
      @org_id = message.dig('host', 'org_id')
      @msg_type = message.dig('type')
    end

    def import
      return unless sources_exist?

      policy_system = V2::PolicySystem.new(policy_id: @policy_id, system_id: @system_id)

      if policy_system.save
        @logger.audit_success("[#{@org_id}] Imported PolicySystem for System #{@system_id} from #{@msg_type} message")
      else
        @logger.audit_fail("[#{@org_id}] Failed to import PolicySystem: " \
                            "#{policy_system.errors.full_messages.join(', ')}")
      end
    end

    private

    def sources_exist?
      MODELS.each do |model|
        model_name = model.name.demodulize
        id = instance_variable_get("@#{model_name.downcase}_id")

        unless model.exists?(id: id)
          @logger.audit_fail("[#{@org_id}] Failed to import PolicySystem: #{model_name} not found with ID #{id}")
          return false
        end
      end

      true
    end
  end
end
