# frozen_string_literal: true

# Methods that are related to computing the score of a profile
module ProfileScoring
  include ProfilePolicyScoring

  def total_host_count
    policy&.total_host_count.to_i || ::Host.where(id: hosts).count
  end

  def test_result_host_count
    policy&.test_result_host_count.to_i
  end

  def compliant_host_count
    policy&.compliant_host_count.to_i
  end

  def unsupported_host_count
    policy&.unsupported_host_count.to_i
  end

  def compliance_score(host)
    return 1 if results(host).count.zero?

    (results(host).count { |result| result == true }) / results(host).count
  end

  def compliant?(host)
    policy&.compliant?(host) || false
  end

  # Disabling MethodLength because it measures things wrong
  # for a multi-line string SQL query.
  def results(host)
    ::Rails.cache.fetch("#{id}/#{host.id}/results") do
      rule_results = ::TestResult.where(profile: self, host: host)
                                 .order('created_at DESC')&.first&.rule_results
      return [] if rule_results.blank?

      rule_results.map do |rule_result|
        %w[pass notapplicable notselected].include? rule_result.result
      end
    end
  end
end
