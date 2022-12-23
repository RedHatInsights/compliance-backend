# frozen_string_literal: true

require 'test_helper'

class RulePolicyTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
  end

  test 'all rules are accessible' do
    assert_empty Pundit.policy_scope(@user, Rule)

    benchmark = FactoryBot.create(:benchmark, :with_rules)

    assert_equal Rule.all, Pundit.policy_scope(@user, Rule)
    assert Pundit.authorize(@user, benchmark.rules, :index?)
    assert Pundit.authorize(@user, benchmark.rules.sample, :show?)
  end
end
