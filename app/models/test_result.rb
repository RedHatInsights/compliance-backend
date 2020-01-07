# frozen_string_literal: true

# Representation of the TestResult XML property in an OpenSCAP report. Holds the
# basic report properties, such as dates, host, and results.
class TestResult < ApplicationRecord
  belongs_to :profile
  belongs_to :host
  has_one :benchmark, through: :profile
  has_many :rule_results, dependent: :delete_all
  has_many :rules, through: :rule_results

  validates :host_id, presence: true,
                      uniqueness: { scope: %i[profile_id end_time] }
  validates :profile_id, presence: true,
                         uniqueness: { scope: %i[host_id end_time] }

  def self.latest(profile_id, host_id)
    where(host_id: host_id, profile_id: profile_id)
      .order('created_at DESC')
      .includes(:rule_results).first
  end
end
