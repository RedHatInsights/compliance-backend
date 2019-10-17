# frozen_string_literal: true

require 'test_helper'

class XCCDFReportMigrationTest < ActiveSupport::TestCase
  setup do
    @profile = Profile.create(
      name: 'footitle',
      benchmark: benchmarks(:one),
      ref_id: 'foorefid'
    )
    @rules = 10.times.map do |i|
      rule = Rule.create(title: "bar#{i}", ref_id: "ruleref#{i}",
                         description: 'baz',
                         benchmark: benchmarks(:one),
                         severity: 'low')
      @profile.rules << rule
      rule
    end
    @host = hosts(:one)
    @rule_results = @rules.map do |rule|
      RuleResult.create(rule: rule, host: @host, result: 'pass')
    end
  end

  test 'migration should just rename rules/profiles if no conflict' do
    original_profile_ref_id = @profile.ref_id
    XCCDFReportMigration.new(Account.new, false).run
    @profile.reload
    @rules.map(&:reload)
    @rule_results.map(&:reload)
    assert_equal(
      "xccdf_org.ssgproject.content_profile_#{original_profile_ref_id}",
      @profile.ref_id
    )
    10.times do |i|
      assert_equal(
        "xccdf_org.ssgproject.content_rule_ruleref#{i}",
        @rules[i].ref_id
      )
    end
    @rule_results.each_with_index do |rule_result, i|
      assert_equal @rules[i].id, rule_result.rule_id
    end
  end

  test 'migration should reassign results if conflict' do
    @profile.update!(account: accounts(:test), hosts: [hosts(:one)])
    conflict_profile = Profile.create!(
      account: accounts(:test),
      hosts: [hosts(:one)],
      name: 'footitle2',
      benchmark: benchmarks(:one),
      ref_id: "xccdf_org.ssgproject.content_profile_#{@profile.ref_id}"
    )
    conflict_rules = 10.times.map do |i|
      rule = Rule.create!(
        title: "bar#{i}",
        ref_id: "xccdf_org.ssgproject.content_rule_ruleref#{i}",
        description: 'baz',
        benchmark: benchmarks(:one),
        severity: 'low'
      )
      conflict_profile.rules << rule
      rule
    end
    original_profile_ref_id = @profile.ref_id
    XCCDFReportMigration.new(accounts(:test), false).run
    assert_empty Profile.where(ref_id: original_profile_ref_id,
                               account: accounts(:test))
    assert_empty Rule.where(ref_id: @rules.map(&:ref_id))
    @rule_results.map(&:reload).each_with_index do |rule_result, i|
      assert_equal conflict_rules[i].id, rule_result.rule_id
    end
  end
end
