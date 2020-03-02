# frozen_string_literal: true

require 'test_helper'

class RulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    RulesController.any_instance.stubs(:authenticate_user)
    User.current = users(:test)
    users(:test).update account: accounts(:test)
    profiles(:one).update(account: accounts(:test))
  end

  test 'index lists all rules' do
    RulesController.any_instance.expects(:policy_scope).with(Rule)
                   .returns(Rule.all).at_least_once
    get rules_url

    assert_response :success
  end

  test 'finds a rule within the user scope' do
    profiles(:one).update rules: [rules(:one)]
    get rule_url(rules(:one).ref_id)

    assert_response :success
  end

  test 'finds a rule with similar slug within the user scope' do
    rules(:two).update(slug: "#{rules(:two).ref_id}-#{SecureRandom.uuid}")
    profiles(:one).update rules: [rules(:two)]
    get rule_url(rules(:two).ref_id)

    assert_response :success
  end

  test 'does not find a rule outside of the user scope' do
    profiles(:one).update rules: [rules(:one)]
    get rule_url(rules(:two).ref_id)

    assert_response :not_found
  end
end
