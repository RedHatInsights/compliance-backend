# frozen_string_literal: true

require 'test_helper'

class RulePolicyTest < ActiveSupport::TestCase
  setup do
    users(:test).account = accounts(:test)
  end

  test 'disallows rules not in the current_user account' do
    assert_empty Pundit.policy_scope(users(:test), Rule)
    Profile.create!(name: 'test', ref_id: 'test',
                    parent_profile: profiles(:one),
                    benchmark: benchmarks(:one), rules: [rules(:one)])
    assert_empty Pundit.policy_scope(users(:test), Rule)
    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(users(:test), rules(:one), :index?)
    end
    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(users(:test), rules(:one), :show?)
    end
  end

  test 'allows rules in the current_user account' do
    assert_empty Pundit.policy_scope(users(:test), Rule)
    Profile.create!(name: 'test', ref_id: 'test',
                    parent_profile: profiles(:one),
                    benchmark: benchmarks(:one), hosts: [hosts(:one)],
                    account: accounts(:test), rules: [rules(:one)])
    assert_includes Pundit.policy_scope(users(:test), Rule), rules(:one)
    assert Pundit.authorize(users(:test), rules(:one), :index?)
    assert Pundit.authorize(users(:test), rules(:one), :show?)
  end

  test 'allows rules from canonical profiles' do
    assert_empty Pundit.policy_scope(users(:test), Rule)
    Profile.create!(name: 'test', ref_id: 'test',
                    benchmark: benchmarks(:one), rules: [rules(:one)])
    assert_includes Pundit.policy_scope(users(:test), Rule), rules(:one)
    assert Pundit.authorize(users(:test), rules(:one), :index?)
    assert Pundit.authorize(users(:test), rules(:one), :show?)
  end
end
