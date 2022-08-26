# frozen_string_literal: true

# Stores the identifier for a rule
class RuleIdentifier < ApplicationRecord
  belongs_to :rule

  validates :label, presence: true, uniqueness: { scope: %i[system rule_id] }
  validates :system, presence: true, uniqueness: { scope: %i[label rule_id] }
  validates :rule, presence: true, uniqueness: { scope: %i[label system] }

  TO_JSON = Arel::Nodes::NamedFunction.new(
    'json_build_object',
    [
      Arel::Nodes::Quoted.new('label'), arel_table[:label],
      Arel::Nodes::Quoted.new('system'), arel_table[:system]
    ]
  )

  def self.from_openscap_parser(op_rule_identifier, rule_id)
    if op_rule_identifier.label # rubocop:disable Style/GuardClause
      find_or_initialize_by(label: op_rule_identifier.label,
                            system: op_rule_identifier.system,
                            rule_id: rule_id)
    end
  end
end
