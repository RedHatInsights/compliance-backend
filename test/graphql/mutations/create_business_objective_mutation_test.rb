# frozen_string_literal: true

require 'test_helper'

class CreateBusinessObjectiveMutationTest < ActiveSupport::TestCase
  test 'create business objective' do
    query = <<-GRAPHQL
       mutation createBusinessObjective($input: createBusinessObjectiveInput!) {
          createBusinessObjective(input: $input) {
             businessObjective {
                 id
                 title
             }
          }
       }
    GRAPHQL

    users(:test).update account: accounts(:test)

    result = Schema.execute(
      query,
      variables: { input: {
        title: 'foobar'
      } },
      context: { current_user: users(:test) }
    )['data']['createBusinessObjective']['businessObjective']

    assert_equal result['title'], 'foobar'
  end
end
