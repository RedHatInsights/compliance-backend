# frozen_string_literal: true

module V2
  # Model link between (Profile) Tailoring and Rule
  class TailoringRule < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :tailoring_rules
    self.primary_key = :id

    belongs_to :tailoring, class_name: 'V2::Tailoring', inverse_of: :tailoring_rules
    belongs_to :rule, class_name: 'V2::Rule'

    validate :matching_security_guide?, on: :create

    def matching_security_guide?
      errors.add(:rule, 'Unassignable rule') if rule.security_guide.id != tailoring.profile.security_guide.id
    end
  end
end
