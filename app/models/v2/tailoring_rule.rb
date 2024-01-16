# frozen_string_literal: true

module V2
  # Model link between (Profile) Tailoring and Rule
  class TailoringRule < ApplicationRecord
    self.table_name = :profile_rules

    belongs_to :tailoring, class_name: 'V2::Tailoring'
    belongs_to :rule, class_name: 'V2::Rule'
  end
end
