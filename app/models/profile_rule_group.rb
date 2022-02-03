# frozen_string_literal: true

# Join table to be able to have a has-many-belongs-to-many relation between
# Profile and RuleGroup
class ProfileRuleGroup < ApplicationRecord
  belongs_to :profile
  belongs_to :rule_group

  validates :profile, presence: true
  validates :rule_group, presence: true, uniqueness: { scope: :profile }
end
