# frozen_string_literal: true

module V1
  # Audit logging methods for Profiles
  module ProfileAudit
    extend ActiveSupport::Concern

    private

    def audit_creation
      audit_success(
        "Created policy #{new_policy.id} with initial profile" \
        " #{new_profile.id} including host assignment and tailoring"
      )
    end

    def audit_bo_creation(business_objective)
      audit_success("Created Business Objective #{business_objective.id}")
    end

    def audit_tailoring_file
      audit_success(
        "Sent computed tailoring file #{tailoring_filename}" \
        " for profile #{profile.id} of policy #{profile.policy_id}"
      )
    end

    def audit_update
      audit_success(
        "Updated profile #{profile.id} and its policy #{profile.policy_id}" \
        ' including host assignment and tailoring'
      )
    end

    def audit_removal(profile)
      audit_success("Removed profile #{profile.id}")
    end
  end
end
