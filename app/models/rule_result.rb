# frozen_string_literal: true

# Models the relationship between host and rules, which result
# did they have at which time. This model would allow us to generate
# reports of compliance at any point in time
class RuleResult < ApplicationRecord
  scoped_search on: %i[id rule_id host_id result]
  belongs_to :host
  belongs_to :rule

  validates :host, presence: true
  validates :rule, presence: true

  SELECTED = %w[pass fail notapplicable error unknown].freeze
  FAIL = %w[fail error unknown notchecked].freeze

  scope :selected, -> { where(result: SELECTED) }
  scope :failed, -> { where(result: FAIL) }
  scope :for_system, ->(host_id) { where(host_id: host_id) }
end
