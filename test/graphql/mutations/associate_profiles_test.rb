# frozen_string_literal: true

require 'test_helper'

class AssociateProfilesMutationTest < ActiveSupport::TestCase
  test 'provide all required arguments' do
    query = <<-GRAPHQL
       mutation associateProfiles($input: associateProfilesInput!) {
          associateProfiles(input: $input) {
             system {
                 id
                 name
             }
          }
       }
    GRAPHQL

    policies(:one).update account: accounts(:test)
    profiles(:one).update account: accounts(:test),
                          policy_object: policies(:one)
    policies(:two).update account: accounts(:test)
    profiles(:two).update account: accounts(:test),
                          policy_object: policies(:two)
    hosts(:one).update account: accounts(:test)
    users(:test).update account: accounts(:test)

    assert_empty hosts(:one).policies

    Schema.execute(
      query,
      variables: { input: {
        id: hosts(:one).id,
        profileIds: [profiles(:one).id, profiles(:two).id]
      } },
      context: { current_user: users(:test) }
    )['data']['associateProfiles']['system']

    assert_equal Set.new(hosts(:one).reload.policies),
                 Set.new([policies(:one), policies(:two)])
  end

  test 'finds inventory systems and creates them in compliance' do
    NEW_ID = '7ccda3fb-bd28-4845-ab5a-061099eae7b3'
    assert_nil(Host.find_by(id: NEW_ID))

    query = <<-GRAPHQL
       mutation associateProfiles($input: associateProfilesInput!) {
          associateProfiles(input: $input) {
             system {
                 id
                 name
             }
          }
       }
    GRAPHQL

    users(:test).update account: accounts(:test)
    policies(:one).update account: accounts(:test)
    profiles(:one).update account: accounts(:test),
                          policy_object: policies(:one)
    policies(:two).update account: accounts(:test)
    profiles(:two).update account: accounts(:test),
                          policy_object: policies(:two)

    @api = mock('HostInventoryAPI')
    HostInventoryAPI.expects(:new).returns(@api)
    @api.expects(:inventory_host).returns(
      'id' => NEW_ID,
      'display_name' => 'newhostname'
    )

    Schema.execute(
      query,
      variables: { input: {
        id: NEW_ID,
        profileIds: [profiles(:one).id, profiles(:two).id]
      } },
      context: { current_user: users(:test) }
    )['data']['associateProfiles']['system']

    assert_not_nil(new_host = Host.find_by(id: NEW_ID))
    assert_equal Set.new(new_host.policies),
                 Set.new([policies(:one), policies(:two)])
  end

  test 'external profiles are kept after associating internal profiles' do
    query = <<-GRAPHQL
       mutation associateProfiles($input: associateProfilesInput!) {
          associateProfiles(input: $input) {
             system {
                 id
                 name
             }
          }
       }
    GRAPHQL
    users(:test).update account: accounts(:test)
    policies(:one).update account: accounts(:test)
    profiles(:one).update account: accounts(:test),
                          policy_object: policies(:one)
    policies(:two).update account: accounts(:test)
    profiles(:two).update account: accounts(:test),
                          policy_object: policies(:two)
    hosts(:one).update account: accounts(:test)

    Schema.execute(
      query,
      variables: { input: {
        id: hosts(:one).id,
        profileIds: [profiles(:one).id, profiles(:two).id]
      } },
      context: { current_user: users(:test) }
    )['data']['associateProfiles']['system']

    assert_equal Set.new([policies(:one), policies(:two)]),
                 Set.new(hosts(:one).reload.policies)
  end
end
