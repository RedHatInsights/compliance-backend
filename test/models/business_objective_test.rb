# frozen_string_literal: true

require 'test_helper'

class BusinessObjectiveTest < ActiveSupport::TestCase
  fixtures :profiles, :business_objectives
  should have_many :profiles
  should validate_presence_of :title

  context 'without_accounts' do
    should 'return orphaned business objectives' do
      profiles(:one).update! business_objective: business_objectives(:one)
      assert_includes BusinessObjective.without_profiles,
                      business_objectives(:two)
      assert_not_includes BusinessObjective.without_profiles,
                          business_objectives(:one)
    end
  end
end
