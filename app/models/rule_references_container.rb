# frozen_string_literal: true

# Model that is holding the additional rule_references field for each Rule
class RuleReferencesContainer < ApplicationRecord
  # FIXME: V2 compatibility - clean up after V2 report parsing refactor
  self.table_name = :v1_rule_references_containers
  self.primary_key = :id

  belongs_to :rule

  validates :rule_id, uniqueness: true

  def self.from_openscap_parser(op_rule, rule_id:, existing: nil)
    container = existing || new(rule_id: rule_id)

    container.assign_attributes(rule_references: op_rule.references.map(&:to_h))

    container
  end
end
