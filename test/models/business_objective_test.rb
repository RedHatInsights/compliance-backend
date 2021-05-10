# frozen_string_literal: true

require 'test_helper'

class BusinessObjectiveTest < ActiveSupport::TestCase
  should have_many :policies
  should have_many(:profiles).through(:policies)
  should have_many(:accounts).through(:policies)
  should validate_presence_of :title

  setup do
    BusinessObjective.delete_all
    @bo = FactoryBot.create_list(:business_objective, 2)
    user = FactoryBot.create(:user)
    FactoryBot.create(
      :policy,
      business_objective: @bo.first,
      account: user.account
    )
  end

  should 'return orphaned business objectives' do
    assert_includes BusinessObjective.without_policies,
                    @bo.last
    assert_not_includes BusinessObjective.without_policies,
                        @bo.first
  end
end
