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

  def self.from_openscap_parser(op_rule_result, rule_ids: {}, host_id: nil,
                                start_time: nil, end_time: nil)
    find_or_initialize_by(rule_id: rule_ids[op_rule_result.id],
                          host_id: host_id, result: op_rule_result.result,
                          start_time: start_time, end_time: end_time)
  end
end
