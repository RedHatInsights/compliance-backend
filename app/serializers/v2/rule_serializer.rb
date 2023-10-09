# frozen_string_literal: true

module V2
  # JSON serialization for an OpenSCAP Rule
  class RuleSerializer < V2::ApplicationSerializer
    attributes :ref_id, :title, :rationale, :description, :severity, :precedence

    derived_attribute :remediation_issue_id, :remediation_available, profiles: [:ref_id], security_guide: [:ref_id]
  end
end
