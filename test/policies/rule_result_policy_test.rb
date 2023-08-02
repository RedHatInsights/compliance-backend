# frozen_string_literal: true

require 'test_helper'

class RuleResultPolicyTest < ActiveSupport::TestCase
  test 'only rules within visible hosts are accessible' do
    stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ)
    user = FactoryBot.create(:user)
    host1 = Host.find(
      FactoryBot.create(:host, org_id: user.account.org_id).id
    )
    assert_includes Pundit.policy_scope(user, Host), host1

    profile1 = FactoryBot.create(
      :profile,
      :with_rules,
      rule_count: 1,
      account: user.account
    )

    tr1 = FactoryBot.create(:test_result, profile: profile1, host: host1)

    rr1 = FactoryBot.create(
      :rule_result,
      host: host1,
      test_result: tr1,
      rule: profile1.rules.first
    )

    account2 = FactoryBot.create(:account)
    host2 = FactoryBot.create(:host, org_id: account2.org_id)
    profile2 = FactoryBot.create(
      :profile,
      :with_rules,
      rule_count: 1,
      account: account2
    )

    tr2 = FactoryBot.create(:test_result, profile: profile2, host: host2)

    rr2 = FactoryBot.create(
      :rule_result,
      host: host2,
      test_result: tr2,
      rule: profile2.rules.first
    )

    assert_includes Pundit.policy_scope(user, RuleResult), rr1
    assert Pundit.authorize(user, rr1, :index?)
    assert Pundit.authorize(user, rr1, :show?)
    assert_not_includes Pundit.policy_scope(user, RuleResult), rr2
  end
end
