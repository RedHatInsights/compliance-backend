# frozen_string_literal: true

# Methods that are shared between system-like models, like
# Hosts and Imagestreams.
module SystemLike
  extend ActiveSupport::Concern

  included do
    has_many :rule_results, dependent: :destroy
    has_many :rules, through: :rule_results, source: :rule
    belongs_to :account_object, optional: true, foreign_key: :org_id,
                                primary_key: :org_id,
                                inverse_of: :hosts, class_name: 'Account'
  end

  def compliant
    result = {}
    test_result_profiles.map do |profile|
      result[profile.ref_id] = profile.compliant?(self)
    end
    result
  end

  def last_scanned(profile_id: nil)
    rel = test_results.latest.order(:end_time)
    rel = rel.where(profile_id: profile_id) if profile_id
    rel.last&.end_time&.iso8601 || 'Never'
  end

  def last_scan_results(profile = nil)
    return profile.results(self) if profile.present?

    test_result_profiles.flat_map do |p|
      p.results(self)
    end
  end

  def rules_passed(profile = nil)
    @rules_passed ||= last_scan_results(profile).count { |result| result }
  end

  def rules_failed(profile = nil)
    @rules_failed ||= last_scan_results(profile).count(&:!)
  end

  def compliance_score
    score = (100 * (rules_passed.to_f / (rules_passed + rules_failed)))
    score.nan? ? 0.0 : score
  end
end
