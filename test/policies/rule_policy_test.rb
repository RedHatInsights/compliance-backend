# frozen_string_literal: true

require 'test_helper'

class RulePolicyTest < ActiveSupport::TestCase
  test 'only rules within account profiles are accessible' do
    assert_empty Pundit.policy_scope(users(:test), Rule)
    users(:test).account = accounts(:test)
    Profile.create(name: 'test', ref_id: 'test',
                   account: accounts(:test), rules: [rules(:one)])
    assert_includes Pundit.policy_scope(users(:test), Rule), rules(:one)
    assert Pundit.authorize(users(:test), rules(:one), :index?)
    assert Pundit.authorize(users(:test), rules(:one), :show?)
    assert_not_includes Pundit.policy_scope(users(:test), Rule), rules(:two)
  end
end
