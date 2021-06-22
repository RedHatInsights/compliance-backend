# frozen_string_literal: true

# Methods that are related to computing the score of a profile or a policy
module ProfilePolicyScoring
  def score(host: nil)
    return super().to_f unless host

    test_results.latest.where(host: host).average(:score).to_f
  end

  def calculate_score!(*_args)
    update!(score: test_results.latest.average(:score).to_f)
  end

  def update_counters!
    # rubocop:disable Rails/SkipsModelValidations
    update_columns(
      total_host_count: hosts.count,
      test_result_host_count: latest_supported_policy_test_result_hosts.count,
      compliant_host_count: latest_supported_policy_test_result_hosts
        .count { |host| compliant?(host) },
      unsupported_host_count: latest_unsupported_policy_test_result_hosts.count
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def latest_supported_policy_test_result_hosts
    ::Host.where(id: latest_test_results.supported.select(:host_id))
  end

  def latest_unsupported_policy_test_result_hosts
    ::Host.where(id: latest_test_results.supported(false).select(:host_id))
  end

  def latest_test_results
    ::TestResult.where(id: test_results.pluck(:id))
                .or(::TestResult.where(profile_id: profiles.pluck(:id))).latest
  end
end
