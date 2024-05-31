# frozen_string_literal: true

module V2
  # Class representing individual rule results unter a test result
  class RuleResult < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :rule_results
    self.ignored_columns += %w[account]

    belongs_to :test_result, class_name: 'V2::TestResult'
    belongs_to :rule, class_name: 'V2::Rule'

    has_one :system, class_name: 'V2::System', through: :test_result
    has_one :tailoring, class_name: 'V2::Tailoring', through: :test_result
    has_one :profile, class_name: 'V2::Profile', through: :tailoring
    has_one :security_guide, class_name: 'V2::SecurityGuide', through: :profile
    has_one :policy, class_name: 'V2::Policy', through: :tailoring
    has_one :report, class_name: 'V2::Report', through: :policy
    has_one :account, class_name: 'V2::Account', through: :policy

    NOT_SELECTED = %w[notapplicable notchecked informational notselected].freeze
    PASSED = %w[pass].freeze
    FAILED = %w[fail error unknown fixed].freeze
    SELECTED = (PASSED + FAILED).freeze

    scope :passed, -> { where(result: PASSED) }
    scope :failed, -> { where(result: FAILED) }
  end
end
