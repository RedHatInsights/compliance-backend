# frozen_string_literal: true

require 'test_helper'

class AccountPolicyTest < ActiveSupport::TestCase
  test 'only accounts within user scope should be accessible' do
    assert_not_includes Pundit.policy_scope(users(:test), Account), accounts(:test)
    users(:test).account = accounts(:test)
    assert_includes Pundit.policy_scope(users(:test), Account), accounts(:test)
  end
end
