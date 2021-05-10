# frozen_string_literal: true

require 'test_helper'

class AccountPolicyTest < ActiveSupport::TestCase
  test 'only accounts within user scope should be accessible' do
    user = FactoryBot.create(:user)
    account = FactoryBot.create(:account)
    assert_not_includes Pundit.policy_scope(user, Account),
                        account
    user.account = account
    assert_includes Pundit.policy_scope(user, Account), account
  end
end
