# frozen_string_literal: true

# JSON API serialization for an OpenSCAP Rule
class RuleSerializer < ApplicationSerializer
  attributes :ref_id, :remediation_issue_id, :title, :rationale, :description,
             :severity, :slug
  belongs_to :benchmark
  has_many :profiles do |rule|
    Pundit.policy_scope(User.current, rule.profiles)
  end
  has_many :rule_references
  has_one :rule_identifier
end
