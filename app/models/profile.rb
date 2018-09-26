# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  has_many :profile_rules, dependent: :destroy
  has_many :rules, through: :profile_rules, source: :rule
end
