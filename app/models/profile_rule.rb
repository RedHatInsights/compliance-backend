# frozen_string_literal: true

# Model for ProfileRules
class ProfileRule < ApplicationRecord
  self.table_name = :profile_rules_v2

  belongs_to :profile, class_name: 'Profile'
  belongs_to :rule, class_name: 'Rule'
end
