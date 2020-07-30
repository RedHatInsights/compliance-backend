# frozen_string_literal: true

# Models rule result references
class RuleReferencesRule < ApplicationRecord
  belongs_to :rule_reference
  belongs_to :rule

  validates :rule, presence: true
  validates :rule_reference, presence: true, uniqueness: { scope: :rule }

  def self.find_unique(rule_references_rules)
    arel_find(rule_references_rules) do |rule_references_rule|
      arel_table[:rule_id].eq(rule_references_rule.rule_id).and(
        arel_table[:rule_reference_id].eq(
          rule_references_rule.rule_reference_id
        )
      )
    end
  end
end
