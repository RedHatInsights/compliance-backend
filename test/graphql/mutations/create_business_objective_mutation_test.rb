# frozen_string_literal: true

require 'test_helper'

class CreateBusinessObjectiveMutationTest < ActiveSupport::TestCase
  test 'create business objective' do
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
end
