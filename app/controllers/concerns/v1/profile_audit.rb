# frozen_string_literal: true

module V1
  # Audit logging methods for Profiles
  module ProfileAudit
    extend ActiveSupport::Concern

    private

    def audit_creation
      audit_success(
        "Created policy #{new_policy.id} with initial profile " \
        "#{new_profile.id}"
      )
      audit_host_assignment
      audit_tailoring
    end

    def audit_bo_creation(business_objective)
      audit_success("Created Business Objective #{business_objective.id}")
    end

    def audit_tailoring_file
      audit_success(
        "Sent computed tailoring file #{tailoring_filename} " \
        "for profile #{profile.id} of policy #{profile.policy_id}"
      )
    end

    def audit_update
      audit_success(
        "Updated profile #{profile.id} and its policy #{profile.policy_id}"
      )
      audit_host_assignment
      audit_tailoring
    end

    def audit_host_assignment
      return unless hosts_added&.nonzero? || hosts_removed&.nonzero?

      audit_success(
        "Updated systems assignment on policy #{profile.policy_id}, " \
        "#{hosts_added} added, #{hosts_removed} removed"
      )
    end

    def audit_tailoring
      return unless rules_added&.nonzero? || rules_removed&.nonzero?

      audit_success(
        "Updated tailoring of profile #{profile.id} " \
        "of policy #{profile.policy_id}, " \
        "#{rules_added} rules added, #{rules_removed} rules removed"
      )
    end

    def audit_removal(profile)
      audit_success("Removed profile #{profile.id}")
    end
  end
end
