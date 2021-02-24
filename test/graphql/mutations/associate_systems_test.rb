# frozen_string_literal: true

require 'test_helper'

class AssociateSystemsMutationTest < ActiveSupport::TestCase
  setup do
    profiles(:one).update account: accounts(:one),
                          policy_object: policies(:one)
    users(:test).update account: accounts(:one)
  end

  test 'provide all required arguments' do
    query = <<-GRAPHQL
       mutation associateSystems($input: associateSystemsInput!) {
          associateSystems(input: $input) {
             profile {
                 id
             }
          }
       }
    GRAPHQL

    assert_empty profiles(:one).assigned_hosts

    Schema.execute(
      query,
      variables: { input: {
        id: profiles(:one).id,
        systemIds: [hosts(:one).id]
      } },
      context: { current_user: users(:test) }
    )['data']['associateSystems']['profile']

    assert_equal Set.new(profiles(:one).policy_object.reload.hosts),
                 Set.new([hosts(:one)])
  end

  test 'removes systems from a profile' do
    query = <<-GRAPHQL
       mutation associateSystems($input: associateSystemsInput!) {
          associateSystems(input: $input) {
             profile {
                 id
             }
          }
       }
    GRAPHQL

    assert_not_empty profiles(:one).hosts

    Schema.execute(
      query,
      variables: { input: {
        id: profiles(:one).id,
        systemIds: []
      } },
      context: { current_user: users(:test) }
    )['data']['associateSystems']['profile']

    assert_empty profiles(:one).policy_object.reload.hosts
    assert_audited 'Updated system associaton of policy'
    assert_audited policies(:one).id
  end
end
