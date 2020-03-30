# frozen_string_literal: true

require 'test_helper'

class TestResultPolicyTest < ActiveSupport::TestCase
  setup do
    assert Pundit.policy_scope(users(:test), TestResult), []
    users(:test).account = accounts(:test)
    users(:test).save
  end

  test 'only test results within visible profiles are accessible' do
    profiles(:one).account = accounts(:test)
    profiles(:one).save
    assert_includes Pundit.policy_scope(users(:test), Profile), profiles(:one)
    test_results(:one).profile = profiles(:one)
    rule_results(:one).host = hosts(:one)
    rule_results(:one).rule = rules(:one)
    test_results(:one).rule_results = [rule_results(:one)]
    # Save without validations to force a TestResult with a profile
    # but without a host
    test_results(:one).save(validate: false)
    assert_includes Pundit.policy_scope(users(:test), TestResult),
                    test_results(:one)
    assert Pundit.authorize(users(:test), test_results(:one), :index?)
    assert Pundit.authorize(users(:test), test_results(:one), :show?)
    assert_not_includes Pundit.policy_scope(users(:test), TestResult),
                        test_results(:two)
  end

  test 'only test results within visible hosts are accessible' do
    hosts(:one).account = accounts(:test)
    hosts(:one).save
    assert_includes Pundit.policy_scope(users(:test), Host), hosts(:one)
    test_results(:one).host = hosts(:one)
    rule_results(:one).host = hosts(:one)
    rule_results(:one).rule = rules(:one)
    test_results(:one).rule_results = [rule_results(:one)]
    # Save without validations to force a TestResult with a host
    # but without a profile
    test_results(:one).save(validate: false)
    assert_includes Pundit.policy_scope(users(:test), TestResult),
                    test_results(:one)
    assert Pundit.authorize(users(:test), test_results(:one), :index?)
    assert Pundit.authorize(users(:test), test_results(:one), :show?)
    assert_not_includes Pundit.policy_scope(users(:test), TestResult),
                        test_results(:two)
  end
end
