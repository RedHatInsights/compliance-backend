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

    stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ)
  end
end
