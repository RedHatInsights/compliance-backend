# frozen_string_literal: true

require 'test_helper'

class SystemQueryTest < ActiveSupport::TestCase
  setup do
    users(:test).update account: accounts(:test)
    hosts(:one).update account: accounts(:test)
  end

  test 'query host owned by the user' do
    query = <<-GRAPHQL
      query System($inventoryId: String!){
          system(id: $inventoryId) {
              name
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { inventoryId: hosts(:one).id },
      context: { current_user: users(:test) }
    )

    assert_equal hosts(:one).name, result['data']['system']['name']
  end

  test 'query host owned by another user' do
    query = <<-GRAPHQL
      query System($inventoryId: String!){
          system(id: $inventoryId) {
              name
          }
      }
    GRAPHQL

    hosts(:one).update account: accounts(:test)
    users(:test).update account: nil

    assert_raises(Pundit::NotAuthorizedError) do
      Schema.execute(
        query,
        variables: { inventoryId: hosts(:one).id },
        context: { current_user: users(:test) }
      )
    end
  end

  test 'some host attributes can be queried without profileId arguments' do
    query = <<-GRAPHQL
    {
        allSystems(perPage: 50, page: 1) {
            id
            name
            profileNames
            compliant
            lastScanned
        }
    }
    GRAPHQL

    profiles(:one).rules << rules(:one)
    profiles(:two).rules << rules(:two)
    hosts(:one).profiles << profiles(:one)
    hosts(:one).profiles << profiles(:two)

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: users(:test) }
    )

    assert_equal "#{profiles(:one).name}, #{profiles(:two).name}",
                 result['data']['allSystems'].first['profileNames']
    assert_not result['data']['allSystems'].first['compliant']
  end

  test 'query attributes with profileId arguments' do
    query = <<-GRAPHQL
    query getSystems($policyId: String) {
        allSystems(perPage: 50, page: 1, profileId: $policyId) {
            id
            name
            rulesPassed(profileId: $policyId)
            rulesFailed(profileId: $policyId)
            lastScanned(profileId: $policyId)
            compliant(profileId: $policyId)
        }
    }
    GRAPHQL

    rule_results(:one).update host: hosts(:one), rule: rules(:one)
    rule_results(:two).update host: hosts(:one), rule: rules(:two)
    profiles(:one).rules << rules(:one)
    profiles(:two).rules << rules(:two)
    hosts(:one).profiles << profiles(:one)
    hosts(:one).profiles << profiles(:two)

    result = Schema.execute(
      query,
      variables: { policyId: profiles(:one).id },
      context: { current_user: users(:test) }
    )

    assert_equal 1, result['data']['allSystems'].first['rulesPassed']
    assert_equal 0, result['data']['allSystems'].first['rulesFailed']
    assert result['data']['allSystems'].first['lastScanned']
    assert result['data']['allSystems'].first['compliant']
  end
end
