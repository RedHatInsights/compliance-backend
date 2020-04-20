# frozen_string_literal: true

require 'test_helper'

class ProfilePolicyTest < ActiveSupport::TestCase
  test 'only noncanonical profiles within the account are accessible' do
    profiles(:two).update!(parent_profile: profiles(:one))
    assert_not profiles(:two).reload.canonical?
    assert_empty Pundit.policy_scope(users(:test), Profile)
    users(:test).account = accounts(:test)
    profiles(:one).account_id = accounts(:test).id
    profiles(:one).hosts = [hosts(:one)]
    profiles(:one).save
    assert_includes Pundit.policy_scope(users(:test), Profile), profiles(:one)
    assert Pundit.authorize(users(:test), profiles(:one), :index?)
    assert Pundit.authorize(users(:test), profiles(:one), :show?)
    assert Pundit.authorize(users(:test), profiles(:one), :update?)
    assert_not_includes Pundit.policy_scope(users(:test), Profile),
                        profiles(:two)
  end
end
