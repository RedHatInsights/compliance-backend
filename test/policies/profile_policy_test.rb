# frozen_string_literal: true

require 'test_helper'

class ProfilePolicyTest < ActiveSupport::TestCase
  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
  end
  test 'only noncanonical profiles within the account and '\
       'canonical profiles are accessible' do
    user = FactoryBot.create(:user)
    account = FactoryBot.create(:account)
    profile1 = FactoryBot.create(:profile, account: account)

    assert_not profile1.reload.canonical?
    assert_not_includes Pundit.policy_scope(user, Profile), profile1
    user.account = account

    profile2 = FactoryBot.create(:profile, account: account)
    host = FactoryBot.create(:host, org_id: account.org_id)
    profile2.policy.update!(hosts: [host])

    assert_includes Pundit.policy_scope(user, Profile), profile2
    assert Pundit.authorize(user, profile2, :index?)
    assert Pundit.authorize(user, profile2, :show?)
    assert Pundit.authorize(user, profile2, :update?)
    assert_includes Pundit.policy_scope(user, Profile), profile1
  end
end
