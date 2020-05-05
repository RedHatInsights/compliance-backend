# frozen_string_literal: true

# Models the relationship between host and rules, which result
# did they have at which time. This model would allow us to generate
# reports of compliance at any point in time
class RuleResult < ApplicationRecord
  scoped_search on: %i[id rule_id host_id result]
  belongs_to :host
  belongs_to :rule
  belongs_to :test_result

  validates :test_result, presence: true,
                          uniqueness: { scope: %i[host_id rule_id] }
  validates :host, presence: true,
                   uniqueness: { scope: %i[test_result_id rule_id] }
  validates :rule, presence: true,
                   uniqueness: { scope: %i[test_result_id host_id] }

  POSSIBLE_RESULTS = %w[pass fail error unknown notapplicable notchecked
                        notselected informational fixed].freeze
  NOT_SELECTED = %w[notapplicable notchecked informational notselected].freeze
  SELECTED = (POSSIBLE_RESULTS - NOT_SELECTED).freeze
  PASSED = %w[pass].freeze
  FAIL = (SELECTED - PASSED).freeze

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
