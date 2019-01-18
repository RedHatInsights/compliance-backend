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
    host_results = results(host)
    host_results.present? && host_results.all?(true)
  end

  # Disabling MethodLength because it measures things wrong
  # for a multi-line string SQL query.
  # rubocop:disable Metrics/MethodLength
  def results(host)
    rule_results = RuleResult.find_by_sql(
      ['SELECT rule_results.* FROM (
          SELECT rr2.*,
             rank() OVER (
                    PARTITION BY rule_id, host_id
                    ORDER BY created_at DESC
             )
          FROM rule_results rr2
          WHERE rr2.host_id = ? AND rr2.rule_id IN
             (SELECT rules.id FROM rules
              INNER JOIN profile_rules
              ON rules.id = profile_rules.rule_id
              WHERE profile_rules.profile_id = ?)
       ) rule_results WHERE RANK = 1', host.id, id]
    )
    rule_results.map do |rule_result|
      %w[pass notapplicable notselected].include? rule_result.result
    end
  end
  # rubocop:enable Metrics/MethodLength

  def score
    return 1 if hosts.blank?

    (hosts.count { |host| compliant?(host) }) / hosts.count
  end
end
