class SeedTestResults < ActiveRecord::Migration[5.2]
  def up
    migrated = 0
    test_results = []
    rule_results_set = []
    ProfileHost.find_each do |profile_host|
      host = profile_host.host
      profile = profile_host.profile
      if host.nil? || profile.nil?
        profile_host.destroy
        next
      end
      puts(" - Migrating results for host #{host.name}"\
           " - profile #{profile.name}")
      rule_results_by_end_time = scan_results(host, profile)
        .group_by(&:end_time)
      rule_results_by_end_time.each do |end_time, rule_results|
        rules_passed = rule_results.count { |rr| RuleResult::PASSED.include?(rr.result) }
        rules_failed = rule_results.count { |rr| RuleResult::FAIL.include?(rr.result) }
        rule_results_set << rule_results
        test_results << TestResult.new(
          host_id: host.id,
          profile_id: profile.id,
          start_time: rule_results[0].start_time || Time.now.utc,
          end_time: rule_results[0].end_time || Time.now.utc,
          score: compliance_score(rules_passed, rules_failed)
        )
      end
      migrated += 1
    end
    imported_test_results = TestResult.import test_results
    imported_test_results.ids.zip(rule_results_set).each do |imported_test_result, rule_results|
      RuleResult.where(id: rule_results.pluck(:id)).update_all(test_result_id: imported_test_result)
    end
    puts("Finished migration of RuleResult to TestResults: #{migrated}")
  end

  def down
    TestResult.delete_all
  end

  def scan_results(host, profile)
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
          ) rule_results',
          host.id, RuleResult::SELECTED, profile.id
      ]
    )
  end

  def compliance_score(rules_passed, rules_failed)
    score = (100 * (rules_passed.to_f / (rules_passed + rules_failed)))
    score.nan? ? 0.0 : score
  end
end
