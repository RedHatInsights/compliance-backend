# frozen_string_literal: true

require 'test_helper'

class HostPolicyTest < ActiveSupport::TestCase
  test 'only hosts matching the account are accessible' do
    user = FactoryBot.create(:user)
    h1 = Host.find(
      FactoryBot.create(:host, account: user.account.account_number, org_id: user.account.org_id).id
    )
    a = FactoryBot.create(:account)
    h2 = Host.find(FactoryBot.create(
      :host,
      account: a.account_number,
      org_id: a.org_id
    ).id)

    assert Pundit.authorize(user, h1, :index?)
    assert Pundit.authorize(user, h1, :show?)
    assert_includes Pundit.policy_scope(user, Host), h1

    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(user, h2, :index?)
    end

    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(user, h2, :show?)
    end

    assert_not_includes Pundit.policy_scope(user, Host), h2
  end
end
