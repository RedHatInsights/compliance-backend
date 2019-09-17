# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  scoped_search on: %i[id name ref_id account_id compliance_threshold]

  has_many :profile_rules, dependent: :delete_all
  has_many :rules, through: :profile_rules, source: :rule
  has_many :profile_hosts, dependent: :delete_all
  has_many :hosts, through: :profile_hosts, source: :host
  has_many :profile_imagestreams, dependent: :destroy
  has_many :imagestreams, through: :profile_imagestreams, source: :imagestream
  belongs_to :policy, optional: true
  belongs_to :account, optional: true
  belongs_to :business_objective, optional: true

  validates :ref_id, uniqueness: { scope: %i[account_id name] }, presence: true
  validates :name, presence: true
  validates :compliance_threshold, numericality: true

  after_update :destroy_orphaned_business_objective

  def destroy_orphaned_business_objective
    return unless previous_changes.include?(:business_objective_id) &&
                  previous_changes[:business_objective_id].first.present?

    business_objective = BusinessObjective.find(
      previous_changes[:business_objective_id].first
    )
    business_objective.destroy if business_objective.profiles.empty?
  end

  def compliance_score(host)
    (results(host).count { |result| result == true }) / results(host).count
  end

  def compliant?(host)
    host_results = results(host)
    host_results.present? &&
      (host_results.count(true) / host_results.count.to_f) >=
        (compliance_threshold / 100.0)
  end

  # Disabling MethodLength because it measures things wrong
  # for a multi-line string SQL query.
  # rubocop:disable Metrics/MethodLength
  def results(host)
    Rails.cache.fetch("#{id}/#{host.id}/results", expires_in: 1.week) do
      rule_results = RuleResult.find_by_sql(
        [
          'SELECT rule_results.* FROM (
           SELECT rr2.*,
              rank() OVER (
                     PARTITION BY rule_id, host_id
                     ORDER BY end_time DESC, created_at DESC
              )
           FROM rule_results rr2
           WHERE rr2.host_id = ? AND rr2.result IN (?) AND rr2.rule_id IN
              (SELECT rules.id FROM rules
               INNER JOIN profile_rules
               ON rules.id = profile_rules.rule_id
               WHERE profile_rules.profile_id = ?)
          ) rule_results WHERE RANK = 1',
          host.id, RuleResult::SELECTED, id
        ]
      )
      rule_results.map do |rule_result|
        %w[pass notapplicable notselected].include? rule_result.result
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def score
    return 1 if hosts.blank?

    (hosts.count { |host| compliant?(host) }).to_f / hosts.count
  end
end
