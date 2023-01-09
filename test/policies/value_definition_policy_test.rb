# frozen_string_literal: true

require 'test_helper'

class ValueDefinitionPolicyTest < ActiveSupport::TestCase
  test 'all value definitions are accessible' do
    user = FactoryBot.create(:user)
    value_definition = FactoryBot.create(:value_definition)

    assert_equal ValueDefinition.all,
                 Pundit.policy_scope(user, ValueDefinition)
    assert Pundit.authorize(user, value_definition, :index?)
  end
end
