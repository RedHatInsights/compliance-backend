# frozen_string_literal: true

require 'test_helper'

class TestResultPolicyTest < ActiveSupport::TestCase
  test 'only rules within visible profiles are accessible' do
    assert Pundit.policy_scope(users(:test), TestResult), []
    users(:test).account = accounts(:test)
    profiles(:one).account = accounts(:test)
    users(:test).save
    profiles(:one).save
    assert_includes Pundit.policy_scope(users(:test), Profile), profiles(:one)
    test_results(:one).host = hosts(:one)
    test_results(:one).profile = profiles(:one)
    rule_results(:one).host = hosts(:one)
    rule_results(:one).rule = rules(:one)
    test_results(:one).rule_results = [rule_results(:one)]
    test_results(:one).save
    assert_includes Pundit.policy_scope(users(:test), TestResult),
                    test_results(:one)
    assert Pundit.authorize(users(:test), test_results(:one), :index?)
    assert Pundit.authorize(users(:test), test_results(:one), :show?)
    assert_not_includes Pundit.policy_scope(users(:test), TestResult),
                        test_results(:two)
  end
end
