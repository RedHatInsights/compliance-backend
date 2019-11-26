# frozen_string_literal: true

# Methods that are shared between system-like models, like
# Hosts and Imagestreams.
module SystemLike
  extend ActiveSupport::Concern

  included do
    scoped_search on: %i[id name]
    has_many :rule_results, dependent: :destroy
    has_many :rules, through: :rule_results, source: :rule
    belongs_to :account, optional: true
  end

  def compliant
    result = {}
    profiles.map do |profile|
      result[profile.ref_id] = profile.compliant?(self)
    end
    result
  end

  def last_scan_results(profile = nil)
    return profile.results(self) if profile.present?

    profiles.flat_map do |p|
      p.results(self)
    end
  end

  def rules_passed(profile = nil)
    last_scan_results(profile).count { |result| result }
  end

  def rules_failed(profile = nil)
    last_scan_results(profile).count(&:!)
  end

  def compliance_score
    score = (100 * (rules_passed.to_f / (rules_passed + rules_failed)))
    score.nan? ? 0.0 : score
  end

  def selected_rules(profile = nil, selected_columns = [])
    rules_for_system = profile.present? ? profile.rules : rules
    selected_rule_ids = RuleResult.selected.where(
      host_id: id
    ).pluck(:rule_id)
    rules_for_system.select(selected_columns).yield_self do |temp_rules|
      temp_rules.where(
        id: selected_rule_ids
      )
    end
  end
end
