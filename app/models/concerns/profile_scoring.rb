# frozen_string_literal: true

# Methods that are related to computing the score of a profile
module ProfileScoring
  include ProfilePolicyScoring

  def compliance_score(host)
    return 1 if results(host).count.zero?

    (results(host).count { |result| result == true }) / results(host).count
  end

  def compliant?(host)
    return policy_object.compliant?(host) if policy_id

    score(host: host) >= compliance_threshold
  end

  # Disabling MethodLength because it measures things wrong
  # for a multi-line string SQL query.
  def results(host)
    Rails.cache.fetch("#{id}/#{host.id}/results") do
      rule_results = TestResult.where(profile: self, host: host)
                               .order('created_at DESC')&.first&.rule_results
      return [] if rule_results.blank?

      rule_results.map do |rule_result|
        %w[pass notapplicable notselected].include? rule_result.result
      end
    end
  end
end
