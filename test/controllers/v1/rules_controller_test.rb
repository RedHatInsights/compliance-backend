# frozen_string_literal: true

require 'test_helper'

module V1
  class RulesControllerTest < ActionDispatch::IntegrationTest
    setup do
      RulesController.any_instance.stubs(:authenticate_user).yields
      User.current = users(:test)
      users(:test).update account: accounts(:test)
      profiles(:one).update(
        account: accounts(:test),
        rules: [rules(:one)]
      )
    end

    test 'index lists all rules' do
      RulesController.any_instance.expects(:policy_scope).with(Rule)
                     .returns(Rule.all).at_least_once
      get v1_rules_url

      assert_response :success
    end

    test 'finds a rule within the user scope' do
      get v1_rule_url(rules(:one).ref_id)
      assert_response :success
    end

    test 'finds a rule with similar slug within the user scope' do
      rules(:two).update(slug: "#{rules(:two).ref_id}-#{SecureRandom.uuid}")
      profiles(:one).update rules: [rules(:two)]
      get v1_rule_url(rules(:two).ref_id)

      assert_response :success
    end

    test 'finds a rule by ID' do
      get v1_rule_url(rules(:one).id)

      assert_response :success
    end

    test 'finds latest canonical rules' do
      assert(profiles(:one).canonical?)
      profiles(:one).rules << rules(:two)
      assert(rules(:two).canonical?)
      assert_includes(Rule.latest, rules(:two))
      assert_not_includes(accounts(:test).profiles.map(&:rules).uniq,
                          rules(:two))
      get v1_rule_url(rules(:two).ref_id)

      assert_response :success
    end
  end
end
