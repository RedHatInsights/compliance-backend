# frozen_string_literal: true

# Models the relationship between host and rules, which result
# did they have at which time. This model would allow us to generate
# reports of compliance at any point in time
class RuleResult < ApplicationRecord
  belongs_to :host
  belongs_to :rule

  validates :host, presence: true
  validates :rule, presence: true
end
