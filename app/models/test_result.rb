# frozen_string_literal: true

# Representation of the TestResult XML property in an OpenSCAP report. Holds the
# basic report properties, such as dates, host, and results.
class TestResult < ApplicationRecord
  belongs_to :profile
  belongs_to :host
  has_one :benchmark, through: :profile
  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results

  validates :host, presence: true,
                   uniqueness: { scope: %i[profile_id end_time] }
  validates :profile, presence: true,
                      uniqueness: { scope: %i[host_id end_time] }
  validates :end_time, presence: true,
                       uniqueness: { scope: %i[host_id profile_id] }

  scope :latest, lambda {
    joins("JOIN (#{latest_without_ids.to_sql}) as tr on "\
          'test_results.profile_id = tr.profile_id AND '\
          'test_results.host_id = tr.host_id AND '\
          'test_results.end_time = tr.end_time')
  }

  def self.latest_without_ids
    group(:profile_id, :host_id)
      .select(:profile_id, :host_id, 'MAX(end_time) as end_time')
  end
end
