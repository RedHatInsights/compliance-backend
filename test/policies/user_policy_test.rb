# frozen_string_literal: true

require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase
  test 'only our user is visible' do
    assert_includes Pundit.policy_scope(users(:test), User), users(:test)
  end
end
