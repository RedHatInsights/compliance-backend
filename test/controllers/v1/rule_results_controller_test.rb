# frozen_string_literal: true

require 'test_helper'

module V1
  class RuleResultsControllerTest < ActionDispatch::IntegrationTest
    setup do
      RuleResultsController.any_instance.expects(:authenticate_user).yields
      User.current = FactoryBot.create(:user)
    end

    test 'index lists all rule results' do
      FactoryBot.create_list(:rule_result, 10)
      RuleResultsController.any_instance.expects(:policy_scope)
                           .with(RuleResult)
                           .returns(RuleResult.all).at_least_once

      get v1_rule_results_url

      assert_response :success
    end

    test 'rule results can be sorted' do
      rr1 = FactoryBot.create(:rule_result, result: 'pass')
      rr2 = FactoryBot.create(:rule_result, result: 'fail')

      RuleResultsController.any_instance.expects(:policy_scope)
                           .with(RuleResult)
                           .returns(RuleResult.all).at_least_once

      get v1_rule_results_url, params: {
        sort_by: %w[result]
      }
      assert_response :success

      rule_results = response.parsed_body['data']

      assert_equal(rule_results.map { |rr| rr['id'] }, [rr2, rr1].map(&:id))
    end
  end
end
