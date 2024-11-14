# frozen_string_literal: true

module V2
  # JSON serialization for Rule Results
  class RuleResultSerializer < V2::ApplicationSerializer
    attributes :result, :rule_id

    derived_attribute :system_id, system: [:id] # This is for the policy to work properly

    derived_attribute :ref_id, rule: [:ref_id]
    derived_attribute :rule_group_id, rule: [:rule_group_id]
    derived_attribute :title, rule: [:title]
    derived_attribute :rationale, rule: [:rationale]
    derived_attribute :description, rule: [:description]
    derived_attribute :severity, rule: [:severity]
    derived_attribute :precedence, rule: [:precedence]
    derived_attribute :identifier, rule: [:identifier]
    derived_attribute :references, rule: [:references]

    derived_attribute :remediation_issue_id,
                      rule: %i[remediation_available ref_id], profile: [:ref_id], security_guide: [:ref_id]
  end
end
