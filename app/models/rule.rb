# frozen_string_literal: true

# Stores information about rules, such as which profiles can it be
# found in, what hosts are associated with it, etceter
class Rule < ApplicationRecord
  extend FriendlyId
  friendly_id :ref_id, use: :slugged

  has_many :profile_rules, dependent: :delete_all
  has_many :profiles, through: :profile_rules, source: :profile
  has_many :rule_results, dependent: :delete_all
  has_many :hosts, through: :rule_results, source: :host

  validates :ref_id, uniqueness: true, presence: true
  validates_associated :profile_rules
  validates_associated :rule_results

  def from_oscap_object(oscap_rule)
    self.ref_id = oscap_rule.id
    self.title = oscap_rule.title
    self.rationale = oscap_rule.rationale
    self.description = oscap_rule.description
    self.severity = oscap_rule.severity
    self
  end

  # Disabling MethodLength because it measures things wrong
  # for a multi-line string SQL query.
  # rubocop:disable Metrics/MethodLength
  def compliant?(host)
    Rails.cache.fetch("#{id}/#{host.id}/compliant", expires_in: 1.week) do
      latest_result = RuleResult.find_by_sql(
        ['SELECT rule_results.* FROM (
          SELECT rr2.*,
             rank() OVER (
                    PARTITION BY rule_id, host_id
                    ORDER BY created_at DESC
             )
          FROM rule_results rr2
          WHERE rr2.host_id = ? AND rr2.rule_id = ?
       ) rule_results WHERE RANK = 1', host.id, id]
      ).last
      return false if latest_result.blank?

      %w[pass notapplicable notselected].include? latest_result.result
    end
  end
  # rubocop:enable Metrics/MethodLength
end
