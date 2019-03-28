# frozen_string_literal: true

require 'test_helper'

class RulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    RulesController.any_instance.stubs(:authenticate_user)
  end

  test 'index lists all rules' do
    RulesController.any_instance.expects(:policy_scope).with(Rule)
                   .returns(Rule.all).at_least_once
    get rules_url

    assert_response :success
  end

  test 'shows a rule' do
    RulesController.any_instance.expects(:authorize)
    relation = mock('relation')
    relation.expects(:find).with('1')
    Rule.expects(:friendly).returns(relation)
    get rule_url(1)

    assert_response :success
  end
end
