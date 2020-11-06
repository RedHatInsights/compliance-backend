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

  test 'query profile policyType' do
    profiles(:one).update!(parent_profile: profiles(:two))

    query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              name
              refId
              policyType
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { id: profiles(:one).id },
      context: { current_user: users(:test) }
    )

    assert_equal profiles(:one).parent_profile.name,
                 result['data']['profile']['policyType']
  end

  test 'query profile with SSG version' do
    query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              refId
              ssgVersion
          }
      }
    GRAPHQL

    assert profiles(:one).benchmark.version

    result = Schema.execute(
      query,
      variables: { id: profiles(:one).id },
      context: { current_user: users(:test) }
    )

    assert_equal profiles(:one).ref_id, result['data']['profile']['refId']
    assert_equal profiles(:one).benchmark.version,
                 result['data']['profile']['ssgVersion']
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

    profiles(:one).update account: accounts(:test),
                          parent_profile: profiles(:two)
    users(:test).update account: nil

    assert_raises(Pundit::NotAuthorizedError) do
      Schema.execute(
        query,
        variables: { id: profiles(:one).id },
        context: { current_user: users(:test) }
      )
    end
  end

  test 'query profile with a policy owned by the user' do
    query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              name
              refId
              policy {
                id
                name
                refId
              }
          }
      }
    GRAPHQL

    policies(:one).update!(account: accounts(:test),
                           hosts: [hosts(:one), hosts(:two)])

    (parent = profiles(:one).dup).update!(account: nil, hosts: [])
    profiles(:one).update!(policy_object: policies(:one),
                           parent_profile: parent)
    profiles(:two).update!(account: accounts(:test),
                           external: true,
                           parent_profile: parent,
                           policy_object: policies(:one))

    result = Schema.execute(
      query,
      variables: { id: profiles(:two).id },
      context: { current_user: users(:test) }
    )

    assert_equal profiles(:two).name, result['data']['profile']['name']
    assert_equal profiles(:two).ref_id, result['data']['profile']['refId']

    assert_equal profiles(:one).id,
                 result['data']['profile']['policy']['id']
    assert_equal profiles(:one).ref_id,
                 result['data']['profile']['policy']['refId']
    assert_equal policies(:one).name,
                 result['data']['profile']['policy']['name']
  end

  test 'query profile with a policy policy profiles owned by the user' do
    query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              name
              refId
              policy {
                profiles {
                  id
                  refId
                }
              }
          }
      }
    GRAPHQL

    policies(:one).update!(account: accounts(:test),
                           hosts: [hosts(:one), hosts(:two)])

    (parent = profiles(:one).dup).update!(account: nil, hosts: [])
    profiles(:one).update!(policy_object: policies(:one),
                           parent_profile: parent)
    profiles(:two).update!(account: accounts(:test),
                           external: true,
                           parent_profile: parent,
                           policy_object: policies(:one))

    result = Schema.execute(
      query,
      variables: { id: profiles(:two).id },
      context: { current_user: users(:test) }
    )

    assert_equal profiles(:two).name, result['data']['profile']['name']
    assert_equal profiles(:two).ref_id, result['data']['profile']['refId']

    returned_profiles = result['data']['profile']['policy']['profiles']
    assert_equal returned_profiles.count, 2
    assert_includes returned_profiles.map { |rp| rp['id'] }, profiles(:one).id
    assert_includes returned_profiles.map { |rp| rp['refId'] },
                    profiles(:one).ref_id
    assert_includes returned_profiles.map { |rp| rp['id'] }, profiles(:two).id
    assert_includes returned_profiles.map { |rp| rp['refId'] },
                    profiles(:two).ref_id
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

    test_results(:one).update(profile: profiles(:one), host: hosts(:one),
                              score: 100)
    test_results(:two).update(profile: profiles(:two), host: hosts(:two),
                              score: 90)
    profiles(:one).rules << rules(:one)
    profiles(:one).rules << rules(:two)
    profiles(:one).update(account: accounts(:test),
                          policy_object: policies(:one))
    policies(:one).update(account: accounts(:test),
                          hosts: [hosts(:one), hosts(:two)])

    result = Schema.execute(
      query,
      variables: {},
      context: { current_user: users(:test) }
    )

    profile1_result = result['data']['allProfiles'].find do |h|
      h['name'] == 'profile1'
    end
    assert_equal 2, profile1_result['totalHostCount']
    assert_equal 1, profile1_result['compliantHostCount']
    assert_not profile1_result['businessObjective']
  end
end
