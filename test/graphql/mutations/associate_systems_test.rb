# frozen_string_literal: true

require 'test_helper'

class AssociateSystemsMutationTest < ActiveSupport::TestCase
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

    profiles(:one).update account: accounts(:test)
    hosts(:one).update account: accounts(:test)
    hosts(:two).update account: accounts(:test)
    users(:test).update account: accounts(:test)

    assert_empty profiles(:one).hosts

    Schema.execute(
      query,
      variables: { input: {
        id: profiles(:one).id,
        systemIds: [hosts(:one).id, hosts(:two).id]
      } },
      context: { current_user: users(:test) }
    )['data']['associateSystems']['profile']

    assert_equal profiles(:one).reload.hosts, [hosts(:one), hosts(:two)]
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

    profiles(:one).update account: accounts(:test)
    hosts(:one).update account: accounts(:test)
    hosts(:two).update account: accounts(:test)
    users(:test).update account: accounts(:test)

    assert_empty profiles(:one).hosts

    @api = mock('HostInventoryAPI')
    HostInventoryAPI.expects(:new).returns(@api)
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

    assert_equal(profiles(:one).hosts.pluck(:id), [NEW_ID])
  end
end
