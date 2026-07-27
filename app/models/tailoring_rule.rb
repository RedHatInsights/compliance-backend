# frozen_string_literal: true

# Model link between (Profile) Tailoring and Rule
class TailoringRule < ApplicationRecord
  belongs_to :tailoring, class_name: 'Tailoring', inverse_of: :tailoring_rules
  belongs_to :rule, class_name: 'Rule'

  validate :matching_security_guide?, on: :create

  def matching_security_guide?
    errors.add(:rule, 'Unassignable rule') if rule.security_guide.id != tailoring.profile.security_guide.id
  end
end
