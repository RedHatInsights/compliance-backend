# frozen_string_literal: true

require 'test_helper'

class ProfileQueryTest < ActiveSupport::TestCase
  setup do
    users(:test).update account: accounts(:test)
    profiles(:one).update account: accounts(:test)
  end

  test 'query profile owned by the user' do
    query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              name
              refId
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { id: profiles(:one).id },
      context: { current_user: users(:test) }
    )

    assert_equal profiles(:one).name, result['data']['profile']['name']
    assert_equal profiles(:one).ref_id, result['data']['profile']['refId']
  end

  test 'query profile owned by another user' do
    query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              name
              refId
          }
      }
    GRAPHQL

    profiles(:one).update account: accounts(:test)
    users(:test).update account: nil

    assert_raises(Pundit::NotAuthorizedError) do
      Schema.execute(
        query,
        variables: { id: profiles(:one).id },
        context: { current_user: users(:test) }
      )
    end
  end

  test 'query all profiles' do
    query = <<-GRAPHQL
    {
        allProfiles {
            id
            name
            totalHostCount
            compliantHostCount
            businessObjective {
               title
            }
        }
    }
    GRAPHQL

    rule_results(:one).update host: hosts(:one), rule: rules(:one)
    rule_results(:two).update host: hosts(:two), rule: rules(:two)
    profiles(:one).rules << rules(:one)
    profiles(:one).rules << rules(:two)
    hosts(:one).profiles << profiles(:one)
    hosts(:two).profiles << profiles(:one)

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: users(:test) }
    )

    assert_equal 2, result['data']['allProfiles'].first['totalHostCount']
    assert_equal 1, result['data']['allProfiles'].first['compliantHostCount']
    assert_not result['data']['allProfiles'].first['businessObjective']
  end
end
