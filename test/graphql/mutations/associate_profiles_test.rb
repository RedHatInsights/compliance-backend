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

    users(:test).update account: accounts(:one)
    policies(:one).update account: accounts(:one)
    profiles(:one).update account: accounts(:one),
                          policy: policies(:one)
    policies(:two).update account: accounts(:one)
    profiles(:two).update account: accounts(:one),
                          policy: policies(:two)

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
    users(:test).update account: accounts(:one)
    policies(:one).update account: accounts(:one)
    profiles(:one).update account: accounts(:one),
                          policy: policies(:one)
    policies(:two).update account: accounts(:one)
    profiles(:two).update account: accounts(:one),
                          policy: policies(:two)

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
    assert_audited 'Associated host'
    assert_audited hosts(:one).id
    assert_audited policies(:one).id
    assert_audited profiles(:two).id
  end
end
