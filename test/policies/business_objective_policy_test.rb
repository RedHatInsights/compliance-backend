# frozen_string_literal: true

require 'test_helper'

class BusinessObjectivePolicyTest < ActiveSupport::TestCase
  test 'only business objectives within the account profiles are accessible' do
    user = FactoryBot.create(:user)
    policy = FactoryBot.create(:policy, account: user.account)

    assert_equal user.account, policy.account
    assert_empty Pundit.policy_scope(user, ::BusinessObjective)

    bo1 = FactoryBot.create(:business_objective)
    bo2 = FactoryBot.create(:business_objective)
    policy.update!(business_objective: bo1)

    assert_includes Pundit.policy_scope(user, ::BusinessObjective), bo1
    assert Pundit.authorize(user, bo1, :index?)
    assert Pundit.authorize(user, bo1, :show?)
    assert_not_includes Pundit.policy_scope(user, ::BusinessObjective), bo2
  end
end
