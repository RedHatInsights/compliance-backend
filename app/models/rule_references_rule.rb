# frozen_string_literal: true

# Models rule result references
class RuleReferencesRule < ApplicationRecord
  belongs_to :rule_reference
  belongs_to :rule

  validates :rule, presence: true
  validates :rule_reference, presence: true, uniqueness: { scope: :rule }
end
