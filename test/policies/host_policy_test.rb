# frozen_string_literal: true

require 'test_helper'

class HostPolicyTest < ActiveSupport::TestCase
  test 'only hosts matching the account are accessible' do
    users(:test).update!(account: accounts(:one))

    assert Pundit.authorize(users(:test), hosts(:one), :index?)
    assert Pundit.authorize(users(:test), hosts(:one), :show?)
    assert_includes Pundit.policy_scope(users(:test), Host), hosts(:one)

    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(users(:test), hosts(:two), :index?)
    end

    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(users(:test), hosts(:two), :show?)
    end

    assert_not_includes Pundit.policy_scope(users(:test), Host), hosts(:two)
  end
end
