# frozen_string_literal: true

require 'test_helper'

class CreateBusinessObjectiveMutationTest < ActiveSupport::TestCase
  QUERY = <<-GRAPHQL
     mutation createBusinessObjective($input: createBusinessObjectiveInput!) {
        createBusinessObjective(input: $input) {
           businessObjective {
               id
               title
           }
        }
     }
  GRAPHQL

  test 'create business objective' do
    user = FactoryBot.create(:user)

    result = Schema.execute(
      QUERY,
      variables: { input: {
        title: 'foobar'
      } },
      context: { current_user: user }
    )['data']['createBusinessObjective']['businessObjective']

    assert_equal result['title'], 'foobar'
    assert_audited 'Created Business Objective'
  end

  test 'does not duplicate business objectives' do
    bo = FactoryBot.create(:business_objective)
    user = FactoryBot.create(:user)

    result = Schema.execute(
      QUERY,
      variables: { input: {
        title: bo.title
      } },
      context: { current_user: user }
    )['data']['createBusinessObjective']['businessObjective']

    assert_equal result['id'], bo.id
    assert_equal result['title'], bo.title
    assert_audited 'Created Business Objective'
  end
end
