# frozen_string_literal: true

# Stores the identifier for a rule
class RuleIdentifier < ApplicationRecord
  belongs_to :rule
end
