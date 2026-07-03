# frozen_string_literal: true

# JSON serialization for an OpenSCAP Rule
class RuleSerializer < ApplicationSerializer
  attributes :ref_id, :title, :rationale, :description, :severity,
             :precedence, :identifier, :references, :value_checks,
             :remediation_available, :rule_group_id

  derived_attribute :remediation_issue_id, :remediation_available,
                    profiles: [:ref_id], security_guide: %i[ref_id version]
end
