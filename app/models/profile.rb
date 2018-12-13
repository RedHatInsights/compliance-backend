# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  has_many :profile_rules, dependent: :destroy
  has_many :rules, through: :profile_rules, source: :rule
  has_many :profile_hosts, dependent: :destroy
  has_many :hosts, through: :profile_hosts, source: :host
  belongs_to :policy, optional: true
  belongs_to :account, optional: true

  validates :ref_id, uniqueness: { scope: :account_id }, presence: true
  validates :name, presence: true

  def compliance_score(host)
    (results(host).count { |result| result == true }) / results(host).count
  end

  def compliant?(host)
    results(host).all? true
  end

  def results(host)
    rules.map do |rule|
      rule.compliant?(host)
    end
  end

  def score
    return 1 if hosts.blank?

    (hosts.count { |host| compliant?(host) }) / hosts.count
  end
end
