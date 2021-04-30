# frozen_string_literal: true

require 'test_helper'

module V1
  class RuleResultsControllerTest < ActionDispatch::IntegrationTest
    setup do
      RuleResultsController.any_instance.expects(:authenticate_user).yields
    end

    test 'index lists all rule results' do
      RuleResult.delete_all # FIXME: remove this after cleaning up the fixtures

      User.current = FactoryBot.create(:user)
      FactoryBot.create_list(:rule_result, 10)

      RuleResultsController.any_instance.expects(:policy_scope)
                           .with(RuleResult)
                           .returns(RuleResult.all).at_least_once
      get v1_rule_results_url

      assert_response :success
    end
  end
end
