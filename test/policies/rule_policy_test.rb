# frozen_string_literal: true

require 'test_helper'

class RulePolicyTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)

    # FactoryBot.create(:canonical_profile, :with_rules)
  end

  test 'disallows rules not in the current_user account' do
    assert_empty Pundit.policy_scope(@user, Rule)

    profile = FactoryBot.create(
      :profile,
      :with_rules,
      account: FactoryBot.create(:account)
    )

    profile.rules = profile.parent_profile.rules
    profile.parent_profile.rules.delete_all

    assert_empty Pundit.policy_scope(@user, Rule)
    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(@user, profile.rules.sample, :index?)
    end
    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(@user, profile.rules.sample, :show?)
    end
  end

  test 'allows rules in the current_user account' do
    assert_empty Pundit.policy_scope(@user, Rule)

    profile = FactoryBot.create(:profile, :with_rules, account: @user.account)
    host = FactoryBot.create(:host, account: @user.account.account_number)
    FactoryBot.create(:test_result, host: host, profile: profile)

    assert_includes Pundit.policy_scope(@user, Rule), profile.rules.sample
    assert Pundit.authorize(@user, profile.rules.sample, :index?)
    assert Pundit.authorize(@user, profile.rules.sample, :show?)
  end

  test 'allows rules from canonical profiles' do
    assert_empty Pundit.policy_scope(@user, Rule)

    profile = FactoryBot.create(:canonical_profile, :with_rules, rule_count: 1)

    assert_includes Pundit.policy_scope(@user, Rule), profile.rules.first
    assert Pundit.authorize(@user, profile.rules.first, :index?)
    assert Pundit.authorize(@user, profile.rules.first, :show?)
  end
end
