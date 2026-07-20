# frozen_string_literal: true

# Database model representing historical results of compliance scans
class HistoricalTestResult < ApplicationRecord
  # FIXME: clean up after the remodel
  self.table_name = :historical_test_results_v2
  self.primary_key = :id

  belongs_to :system, class_name: 'System', optional: true
  belongs_to :tailoring, class_name: 'Tailoring'

  has_one :profile, class_name: 'Profile', through: :tailoring
  has_one :security_guide, class_name: 'SecurityGuide', through: :profile
  has_one :policy, class_name: 'Policy', through: :tailoring
  has_one :report, class_name: 'Report', through: :policy
  has_one :account, class_name: 'Account', through: :policy

  has_many :rule_results, class_name: 'RuleResult', dependent: :destroy
end
