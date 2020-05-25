# frozen_string_literal: true

require 'test_helper'

class BusinessObjectivePolicyTest < ActiveSupport::TestCase
  test 'only business objectives within the account profiles are accessible' do
    assert_empty Pundit.policy_scope(users(:test), ::BusinessObjective)
    users(:test).account = accounts(:test)
    profiles(:one).account_id = accounts(:test).id
    profiles(:one).business_objective = business_objectives(:one)
    profiles(:one).save
    assert_includes Pundit.policy_scope(users(:test), ::BusinessObjective),
                    business_objectives(:one)
    assert Pundit.authorize(users(:test), business_objectives(:one), :index?)
    assert Pundit.authorize(users(:test), business_objectives(:one), :show?)
    assert_not_includes Pundit.policy_scope(users(:test), ::BusinessObjective),
                        business_objectives(:two)
  end
end
