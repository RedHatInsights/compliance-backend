# frozen_string_literal: true

require 'test_helper'

class UpstreamRuleBindingsRemoverTest < ActiveSupport::TestCase
  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    account = FactoryBot.create(:account)
    host = FactoryBot.create(:host, org_id: account.org_id)
    @profile = FactoryBot.create(
      :profile,
      :with_rules,
      account: account,
      upstream: false
    )
    @profile.policy.update!(hosts: [host])

    d_rules, u_rules = @profile.rules.in_groups_of(3, false)
    u_rules.map { |rule| rule.update!(upstream: true) }
    d_rules.map { |rule| rule.update!(upstream: false) }

    tr = FactoryBot.create(:test_result, profile: @profile, host: host)
    @dead_rule = u_rules.last

    (d_rules + [u_rules.first]).each do |rule|
      FactoryBot.create(:rule_result, test_result: tr, rule: rule, host: host)
    end
  end

  test 'removes the upstream rule bindings without test results' do
    assert_equal 5, @profile.rules.count
    assert_equal 4, RuleResult.count

    assert_difference('ProfileRule.count' => -2) do
      UpstreamRuleBindingsRemover.run!
    end

    assert_equal 4, RuleResult.count
    assert_equal 4, @profile.rules.reload.count
    assert @dead_rule.profiles.empty?
  end
end
