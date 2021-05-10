# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  test 'only our user is visible' do
    user = FactoryBot.create(:user)

    assert_includes Pundit.policy_scope(user, User), user
    assert Pundit.authorize(user, user, :show?)
  end
end
