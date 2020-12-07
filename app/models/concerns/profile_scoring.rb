# frozen_string_literal: true

# Methods that are related to computing the score of a profile
module ProfileScoring
  include ProfilePolicyScoring

  def total_host_count
    if policy_object
      Host.where(id: assigned_hosts).count
    else
      Host.where(id: hosts).count
    end
  end

  def test_result_host_count
    latest_supported_policy_test_result_hosts.count
  end

  def compliant_host_count
    latest_supported_policy_test_result_hosts.count { |host| compliant?(host) }
  end

  def unsupported_host_count
    Host.where(id: latest_policy_test_results.supported(false).select(:host_id))
        .count
  end

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

  private

  def latest_supported_policy_test_result_hosts
    Host.where(id: latest_policy_test_results.supported.select(:host_id))
  end

  def latest_policy_test_results
    TestResult.where(id: test_results)
              .or(TestResult.where(id: policy_test_results))
              .latest
  end
end
