# frozen_string_literal: true

require 'test_helper'

module V1
  class RulesControllerTest < ActionDispatch::IntegrationTest
    setup do
      RulesController.any_instance.stubs(:authenticate_user).yields
      User.current = FactoryBot.create(:user)
      @profile = FactoryBot.create(:profile, :with_rules)
    end

    test 'index lists all rules' do
      RulesController.any_instance.expects(:policy_scope).with(Rule)
                     .returns(Rule.all).at_least_once
      get v1_rules_url

      assert_response :success
    end

    test 'finds a rule within the user scope' do
      get v1_rule_url(@profile.rules.first.ref_id)
      assert_response :success
    end

    test 'finds a rule with similar slug within the user scope' do
      @profile.rules.first.update(
        slug: "#{@profile.rules.first.ref_id}-#{SecureRandom.uuid}"
      )

      get v1_rule_url(@profile.rules.first.ref_id)
      assert_response :success
    end

    test 'finds a rule by ID' do
      get v1_rule_url(@profile.rules.first.id)

      assert_response :success
    end

    test 'finds latest canonical rules' do
      parent = FactoryBot.create(:canonical_profile, :with_rules, rule_count: 1)

      assert_includes(Rule.latest, parent.rules.last)
      assert_not_includes(User.current.account.profiles.map(&:rules).uniq,
                          parent.rules.last)
      get v1_rule_url(parent.rules.last.ref_id)

      assert_response :success
    end
  end
end
