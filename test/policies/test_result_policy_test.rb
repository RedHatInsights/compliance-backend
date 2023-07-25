# frozen_string_literal: true

require 'test_helper'

class TestResultPolicyTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    account2 = FactoryBot.create(:account)

    @profile1 = FactoryBot.create(:profile, :with_rules, account: @user.account)
    @profile2 = FactoryBot.create(:profile, :with_rules, account: account2)

    @host1 = Host.find(
      FactoryBot.create(:host, org_id: @user.account.org_id).id
    )
    @host2 = Host.find(
      FactoryBot.create(:host, org_id: account2.org_id).id
    )

    @tr1 = FactoryBot.create(
      :test_result,
      host: @host1,
      profile: @profile1
    )

    @tr2 = FactoryBot.create(
      :test_result,
      host: @host2,
      profile: @profile2
    )

    @rr1 = FactoryBot.create(
      :rule_result,
      host: @host1,
      rule: @profile1.rules.first,
      test_result: @tr1
    )

    @rr2 = FactoryBot.create(
      :rule_result,
      host: @host1,
      rule: @profile2.rules.first,
      test_result: @tr2
    )

    stub_rbac_permissions(Rbac::INVENTORY_VIEWER)
  end

  test 'only test results within visible profiles are accessible' do
    assert_not @tr2.profile.canonical?
    assert_includes Pundit.policy_scope(@user, Profile), @profile1

    @tr1.host = nil
    @tr1.save(validate: false)

    assert_includes Pundit.policy_scope(@user, TestResult), @tr1
    assert Pundit.authorize(@user, @tr1, :index?)
    assert Pundit.authorize(@user, @tr1, :show?)
    assert_not_includes Pundit.policy_scope(@user, TestResult), @tr2
  end

  test 'only test results within visible hosts are accessible' do
    assert_not @tr2.profile.canonical?
    assert_includes Pundit.policy_scope(@user, Host), @host1

    @tr1.profile = nil
    @tr1.save(validate: false)

    assert_includes Pundit.policy_scope(@user, TestResult), @tr1
    assert Pundit.authorize(@user, @tr1, :index?)
    assert Pundit.authorize(@user, @tr1, :show?)
    assert_not_includes Pundit.policy_scope(@user, TestResult), @tr2
  end
end
