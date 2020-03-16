# frozen_string_literal: true

# Models the relationship between host and rules, which result
# did they have at which time. This model would allow us to generate
# reports of compliance at any point in time
class RuleResult < ApplicationRecord
  scoped_search on: %i[id rule_id host_id result]
  belongs_to :host
  belongs_to :rule
  belongs_to :test_result

  validates :test_result, presence: true
  validates :host, presence: true
  validates :rule, presence: true

  SELECTED = %w[pass fail notapplicable error unknown].freeze
  FAIL = %w[fail error unknown notchecked].freeze
  PASSED = %w[pass notapplicable].freeze

  scope :passed, -> { where(result: PASSED) }
  scope :selected, -> { where(result: SELECTED) }
  scope :failed, -> { where(result: FAIL) }
  scope :for_system, ->(host_id) { where(host_id: host_id) }

  def self.from_openscap_parser(op_rule_result, test_result_id: nil,
                                rule_id: nil, host_id: nil)
    find_or_initialize_by(
      test_result_id: test_result_id,
      rule_id: rule_id,
      host_id: host_id,
      result: op_rule_result.result
    )
  end
end
