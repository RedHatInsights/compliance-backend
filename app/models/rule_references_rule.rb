# frozen_string_literal: true

# Models rule result references
class RuleReferencesRule < ApplicationRecord
  belongs_to :rule_reference
  belongs_to :rule
end
