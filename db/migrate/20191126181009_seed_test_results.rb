class SeedTestResults < ActiveRecord::Migration[5.2]
  def change
    ProfileHost.each do |profile_host|
      host = profile_host.host
      profile = profile_host.profile
      test_result = TestResult.new(
        host: host,
        profile: profile
      )

      rule_result_ids = []
      host.last_scan_results(profile).each do |rule_result|
        rule_result_ids << rule_result.id
      end

      latest_rule_results = RuleResult.where(id: rule_result_ids)
      latest_rule_results.update_all(test_result: test_result)
      test_result.update(
        start_time: latest_rule_results[0].start_time,
        end_time: latest_rule_results.end_time,
        score: compliance_score(host.rules_passed(profile),
                                host.rules_failed(profile))
      )
    end
  end

  def compliance_score(rules_passed, rules_failed)
    score = (100 * (rules_passed.to_f / (rules_passed + rules_failed)))
    score.nan? ? 0.0 : score
  end

end
