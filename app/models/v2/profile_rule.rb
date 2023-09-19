# frozen_string_literal: true

module V2
  # Model for ProfileRules
  class ProfileRule < ApplicationRecord
    self.table_name = :profile_rules

    belongs_to :profile, class_name: 'V2::Profile'
    belongs_to :rule, class_name: 'V2::Rule'
  end
end
