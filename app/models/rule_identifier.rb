# frozen_string_literal: true

# Stores the identifier for a rule
class RuleIdentifier < ApplicationRecord
  belongs_to :rule

  validates :label, presence: true
  validates :system, presence: true

  def self.from_oscap_rule(oscap_rule)
    new(oscap_rule.identifier) if oscap_rule.identifier.dig(:label)
  end
end
