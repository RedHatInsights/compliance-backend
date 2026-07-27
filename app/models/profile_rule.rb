# frozen_string_literal: true

# Model for ProfileRules
class ProfileRule < ApplicationRecord
  belongs_to :profile, class_name: 'Profile'
  belongs_to :rule, class_name: 'Rule'
end
