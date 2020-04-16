# frozen_string_literal: true

# Methods that are related to computing the score of a profile
module ProfileScoring
  def compliance_score(host)
    return 1 if results(host).count.zero?

    (results(host).count { |result| result == true }) / results(host).count
  end

  def compliant?(host)
    score(host: host) >= compliance_threshold
  end

  def rules_for_system(host, selected_columns = [:id])
    host.selected_rules(self, selected_columns)
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

  def score(host: nil)
    results = test_results.latest
    results = results.where(host: host) if host
    return 0 if results.blank?

    ((scores = results.pluck(:score)).sum / scores.size).to_f
  end
end
