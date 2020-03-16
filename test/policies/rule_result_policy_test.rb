# frozen_string_literal: true

require 'test_helper'

class RuleResultPolicyTest < ActiveSupport::TestCase
  test 'only rules within visible hosts are accessible' do
    assert Pundit.policy_scope(users(:test), RuleResult), []
    users(:test).account = accounts(:test)
    hosts(:one).account = accounts(:test)
    users(:test).save
    hosts(:one).save
    assert_includes Pundit.policy_scope(users(:test), Host), hosts(:one)
    rule_results(:one).host = hosts(:one)
    rule_results(:one).rule = rules(:one)
    rule_results(:one).test_result = test_results(:one)
    rule_results(:one).save
    assert_includes Pundit.policy_scope(users(:test), RuleResult),
                    rule_results(:one)
    assert Pundit.authorize(users(:test), rule_results(:one), :index?)
    assert Pundit.authorize(users(:test), rule_results(:one), :show?)
    assert_not_includes Pundit.policy_scope(users(:test), RuleResult),
                        rule_results(:two)
  end
end
