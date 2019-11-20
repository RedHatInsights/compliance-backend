# frozen_string_literal: true

# Stores the identifier for a rule
class RuleIdentifier < ApplicationRecord
  belongs_to :rule

  validates :label, presence: true
  validates :system, presence: true

  class << self
    def from_openscap_parser(op_rule_identifier, rule_id)
      if op_rule_identifier.label # rubocop:disable Style/GuardClause
        find_or_initialize_by(label: op_rule_identifier.label,
                              system: op_rule_identifier.system,
                              rule_id: rule_id)
      end
    end

    def preexisting_from_oscap_parser(new_rules)
      ::RuleIdentifier.where(
        label: new_rules.map { |r| r.op_source.identifier.label },
        rule_id: new_rules.map(&:id)
      )
    end
  end
end
