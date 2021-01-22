# frozen_string_literal: true

require 'test_helper'

class AssociateSystemsMutationTest < ActiveSupport::TestCase
  setup do
    profiles(:one).update account: accounts(:test),
                          policy_object: policies(:one)
    hosts(:one).update account: accounts(:test)
    hosts(:two).update account: accounts(:test)
    users(:test).update account: accounts(:test)
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
        systemIds: [hosts(:one).id, hosts(:two).id]
      } },
      context: { current_user: users(:test) }
    )['data']['associateSystems']['profile']

    assert_equal Set.new(profiles(:one).policy_object.reload.hosts),
                 Set.new([hosts(:one), hosts(:two)])
  end

  test 'finds inventory systems and creates them in compliance' do
    query = <<-GRAPHQL
       mutation associateSystems($input: associateSystemsInput!) {
          associateSystems(input: $input) {
             profile {
                 id
             }
          }
       }
    GRAPHQL

    NEW_ID = '7ccda3fb-bd28-4845-ab5a-061099eae7b3'

    assert_empty profiles(:one).assigned_hosts

    @api = mock('HostInventoryApi')
    HostInventoryApi.expects(:new).returns(@api)
    @api.expects(:inventory_host).returns(
      'id' => NEW_ID,
      'display_name' => 'newhostname'
    )

    Schema.execute(
      query,
      variables: { input: {
        id: profiles(:one).id,
        systemIds: [NEW_ID]
      } },
      context: { current_user: users(:test) }
    )['data']['associateSystems']['profile']

    assert_equal(profiles(:one).assigned_hosts.pluck(:id), [NEW_ID])
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
  end
end
