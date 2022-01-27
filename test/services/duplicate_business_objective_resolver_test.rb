# frozen_string_literal: true

require 'test_helper'
require './db/migrate/20220127054239_deduplicate_business_objectives'

class DuplicateBusinessObjectiveResolverTest < ActiveSupport::TestCase
  setup do
    @account = FactoryBot.create(:account)

    @policies = 3.times.map do
      FactoryBot.create(
        :policy,
        account: @account,
        business_objective: FactoryBot.create(:business_objective, title: 'foo')
      )
    end
  end

  test 'resolves duplicate accounts' do
    assert_difference('BusinessObjective.count' => -2) do
      DuplicateBusinessObjectiveResolver.run!
    end
  end

  test 'assigns related entities to the deduplicated accounts' do
    DuplicateBusinessObjectiveResolver.run!

    assert_equal 1, @policies.map(&:reload).map(&:business_objective).uniq.count
  end
end
