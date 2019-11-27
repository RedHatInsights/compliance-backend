class SeedTestResults < ActiveRecord::Migration[5.2]
  def change
    ProfileHost.find_each do |profile_host|
      host = profile_host.host
      profile = profile_host.profile
      test_result = TestResult.create(
        host: host,
        profile: profile
      )

      rule_result_ids = []
      latest_scan_results(host, profile).each do |rule_result|
        rule_result_ids << rule_result.id
      end

      latest_rule_results = RuleResult.where(id: rule_result_ids)
      latest_rule_results.update_all(test_result_id: test_result.id)
      test_result.update(
        start_time: latest_rule_results[0].start_time,
        end_time: latest_rule_results[0].end_time,
        score: compliance_score(host.rules_passed(profile),
                                host.rules_failed(profile))
      )
    end
  end

  def latest_scan_results(host, profile)
    RuleResult.find_by_sql(
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
          host.id, RuleResult::SELECTED, profile.id
      ]
    )
  end

  def compliance_score(rules_passed, rules_failed)
    score = (100 * (rules_passed.to_f / (rules_passed + rules_failed)))
    score.nan? ? 0.0 : score
  end

end
