# frozen_string_literal: true

# Models the relationship between host and rules, which result
# did they have at which time. This model would allow us to generate
# reports of compliance at any point in time
class RuleResult < ApplicationRecord
  scoped_search on: %i[id rule_id host_id result], only_explicit: true
  scoped_search on: :result
  belongs_to :host, optional: true
  belongs_to :rule
  belongs_to :test_result
  has_one :profile, through: :test_result

  validates :test_result, presence: true,
                          uniqueness: { scope: %i[host_id rule_id] }
  validates :host, presence: true, on: :create
  validates :host_id, presence: true,
                      uniqueness: { scope: %i[test_result_id rule_id] }
  validates :rule, presence: true,
                   uniqueness: { scope: %i[test_result_id host_id] }

  sortable_by :result
  default_sort :host_id

  POSSIBLE_RESULTS = %w[pass fail error unknown notapplicable notchecked
                        notselected informational fixed].freeze
  NOT_SELECTED = %w[notapplicable notchecked informational notselected].freeze
  SELECTED = (POSSIBLE_RESULTS - NOT_SELECTED).freeze
  PASSED = %w[pass].freeze
  FAILED = (SELECTED - PASSED).freeze

  scope :passed, -> { where(result: PASSED) }
  scope :selected, -> { where(result: SELECTED) }
  scope :failed, -> { where(result: FAILED) }
  scope :for_system, ->(host_id) { where(host_id: host_id) }
  scope :for_policy, ->(policy_id) { joins(:profile).where(profiles: ::Profile.in_policy(policy_id)) }
  scope :latest, ->(policy_id) { for_policy(policy_id).joins(:test_result).joins(::TestResult.with_latest) }

  # When requesting rule results, the DB response is scoped down by org_id numbers on the joined inventory. By
  # using the same index to join hosts and count results, we can save a lot of time.
  def self.count_by
    :host_id
  end

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
