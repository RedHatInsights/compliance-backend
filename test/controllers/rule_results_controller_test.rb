# frozen_string_literal: true

require 'test_helper'

class RuleResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    RuleResultsController.any_instance.expects(:authenticate_user)
  end

  test 'index lists all rule results' do
    RuleResultsController.any_instance.expects(:policy_scope).with(RuleResult)
                         .returns(RuleResult.all).at_least_once
    get rule_results_url

    assert_response :success
  end
end
