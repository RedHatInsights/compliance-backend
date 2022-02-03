# frozen_string_literal: true

# Join table with the has-many-belongs-to-many relations between RuleGroup and Rule
class RuleGroupRule < ApplicationRecord
  # These keep track of the parent-child relationship between rules and rule_groups
  belongs_to :rule
  belongs_to :rule_group

  validates :rule_group, presence: true
  validates :rule, presence: true, uniqueness: { scope: :rule_group }
end
