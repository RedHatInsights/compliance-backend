# frozen_string_literal: true

require 'test_helper'

class BusinessObjectiveTest < ActiveSupport::TestCase
  test 'query host owned by the user' do
    query = <<-GRAPHQL
      {
          businessObjectives {
              id
              title
          }
      }
    GRAPHQL

    users(:test).update account: accounts(:test)
    profiles(:one).update(account: accounts(:test), hosts: [hosts(:one)],
                          business_objective: business_objectives(:one))

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: users(:test) }
    )

    assert_equal business_objectives(:one).id,
                 result['data']['businessObjectives'].first['id']
    assert_equal business_objectives(:one).title,
                 result['data']['businessObjectives'].first['title']
  end
end
