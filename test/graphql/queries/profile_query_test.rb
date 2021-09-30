# frozen_string_literal: true

require 'test_helper'

class ProfileQueryTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @profile = FactoryBot.create(
      :profile,
      :with_rules,
      rule_count: 2,
      account: @user.account
    )
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
      variables: { id: @profile.id },
      context: { current_user: @user }
    )

    assert_equal @profile.name, result['data']['profile']['name']
    assert_equal @profile.ref_id, result['data']['profile']['refId']
  end

  test 'query profile policyType' do
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
      variables: { id: @profile.id },
      context: { current_user: @user }
    )

    assert_equal @profile.parent_profile.name,
                 result['data']['profile']['policyType']
  end

  test 'query profile parentProfileId' do
    query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              parentProfileId
          }
      }
    GRAPHQL

    result = Schema.execute(
      query,
      variables: { id: @profile.id },
      context: { current_user: @user }
    )

    assert_equal @profile.parent_profile_id,
                 result['data']['profile']['parentProfileId']
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

    assert @profile.benchmark.version

    result = Schema.execute(
      query,
      variables: { id: @profile.id },
      context: { current_user: @user }
    )

    assert_equal @profile.ref_id, result['data']['profile']['refId']
    assert_equal @profile.benchmark.version,
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

    @profile.update!(account: FactoryBot.create(:account))

    assert_raises(Pundit::NotAuthorizedError) do
      Schema.execute(
        query,
        variables: { id: @profile.id },
        context: { current_user: @user }
      )
    end
  end

  context 'policy profiles' do
    setup do
      @hosts = FactoryBot.create_list(
        :host,
        2,
        account: @user.account.account_number
      )

      @profile2 = FactoryBot.create(
        :profile,
        policy: @profile.policy,
        ref_id: @profile.ref_id,
        name: @profile.name,
        account: @user.account,
        external: true
      )

      @profile.policy.update!(hosts: @hosts)
    end

    should 'query profile with a policy owned by the user' do
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

      result = Schema.execute(
        query,
        variables: { id: @profile2.id },
        context: { current_user: @user }
      )

      assert_equal @profile.policy.name, result['data']['profile']['name']
      assert_equal @profile2.ref_id, result['data']['profile']['refId']

      assert_equal @profile.id,
                   result['data']['profile']['policy']['id']
      assert_equal @profile.ref_id,
                   result['data']['profile']['policy']['refId']
      assert_equal @profile.name,
                   result['data']['profile']['policy']['name']
    end

    should 'query profile with a policy profiles using first policy profile' \
    ' owned by the user' do
      query = <<-GRAPHQL
      query Profile($id: String!){
          profile(id: $id) {
              id
              name
              description
              refId
              policy {
                profiles {
                  id
                  refId
                  name
                  description
                }
              }
          }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { id: @profile.id },
        context: { current_user: @user }
      )

      assert_equal @profile.policy.name, result['data']['profile']['name']
      assert_equal @profile.policy.description,
                   result['data']['profile']['description']
      assert_equal @profile.ref_id, result['data']['profile']['refId']

      returned_profiles = result['data']['profile']['policy']['profiles']
      assert_equal returned_profiles.count, 2

      policy_profile =
        returned_profiles.find { |rp| rp['id'] == @profile.id }
      assert_equal @profile.ref_id, policy_profile['refId']
      assert_equal @profile.policy.name, policy_profile['name']
      assert_equal @profile.policy.description, policy_profile['description']

      second_profile =
        returned_profiles.find { |rp| rp['id'] == @profile2.id }
      assert_equal @profile2.ref_id, second_profile['refId']
      assert_equal @profile.policy.name, second_profile['name']
      assert_equal @profile.policy.description, second_profile['description']
    end

    should 'query profile with a policy profiles using any policy profile' \
           ' owned by the user' do
      query = <<-GRAPHQL
        query Profile($id: String!){
            profile(id: $id) {
                id
                name
                description
                refId
                policy {
                  profiles {
                    id
                    refId
                    name
                    description
                  }
                }
            }
        }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: { id: @profile2.id },
        context: { current_user: @user }
      )

      assert_equal @profile.policy.name, result['data']['profile']['name']
      assert_equal @profile2.ref_id, result['data']['profile']['refId']

      returned_profiles = result['data']['profile']['policy']['profiles']
      assert_equal returned_profiles.count, 2

      policy_profile =
        returned_profiles.find { |rp| rp['id'] == @profile.id }
      assert_equal @profile.ref_id, policy_profile['refId']
      assert_equal @profile.policy.name, policy_profile['name']
      assert_equal @profile.policy.description, policy_profile['description']

      second_profile =
        returned_profiles.find { |rp| rp['id'] == @profile2.id }
      assert_equal @profile2.ref_id, second_profile['refId']
      assert_equal @profile.policy.name, second_profile['name']
      assert_equal @profile.policy.description, second_profile['description']
    end

    should 'search by upstream flag' do
      @profile.update!(upstream: true)
      @profile2.update!(upstream: false)

      query = <<-GRAPHQL
      {
        profiles(search: "upstream=false") {
          edges {
            node {
              id
            }
          }
        }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: {},
        context: { current_user: @user }
      )

      profiles = result['data']['profiles']['edges']

      assert_equal 1, profiles.count
      assert_equal @profile2.id, profiles.first['node']['id']
    end

    should 'search for downstream profiles and its nested downstream rules' do
      @profile.update!(upstream: false)
      rule = @profile.rules.first
      rule.update!(upstream: false)

      query = <<-GRAPHQL
      {
        profiles(search: "upstream=false") {
          edges {
            node {
              id
              rules: downstreamRules {
                id
              }
            }
          }
        }
      }
      GRAPHQL

      result = Schema.execute(
        query,
        variables: {},
        context: { current_user: @user }
      )

      profiles = result['data']['profiles']['edges']

      assert_equal 1, profiles.count
      assert_equal @profile.id, profiles.first['node']['id']
      assert_equal 1, profiles.first['node']['rules'].count
      assert_equal rule.id, profiles.first['node']['rules'].first['id']
    end

    should 'sort results' do
      query = <<-GRAPHQL
      {
        profiles(search: "canonical=false", sortBy: ["name", "osMinorVersion:desc"]) {
          edges {
            node {
              id
              name
              osMinorVersion
            }
          }
        }
      }
      GRAPHQL

      @profile.update!(os_minor_version: 2, name: 'foo')
      @profile2.update!(os_minor_version: 3, name: 'foo')

      result = Schema.execute(
        query,
        variables: {},
        context: { current_user: @user }
      )

      profiles = result['data']['profiles']['edges']

      assert_equal '3', profiles.first['node']['osMinorVersion']
      assert_equal '2', profiles.second['node']['osMinorVersion']
    end

    should 'query all profiles' do
      query = <<-GRAPHQL
      {
          allProfiles {
              id
              name
              totalHostCount
              testResultHostCount
              compliantHostCount
              unsupportedHostCount
              osMinorVersion
              osVersion
              businessObjective {
                 title
              }
              hosts {
                 id
              }
          }
      }
      GRAPHQL

      FactoryBot.create(
        :test_result,
        profile: @profile,
        host: @hosts.first,
        score: 100
      )

      FactoryBot.create(
        :test_result,
        profile: @profile2,
        host: @hosts.last,
        score: 90,
        supported: false
      )

      @profile.update!(os_minor_version: 4)
      @profile.policy.update!(compliance_threshold: 95, hosts: [@hosts.first])

      result = Schema.execute(
        query,
        variables: {},
        context: { current_user: @user }
      )

      profile1_result = result['data']['allProfiles'].find do |h|
        h['id'] == @profile.id
      end
      profile2_result = result['data']['allProfiles'].find do |h|
        h['id'] == @profile2.id
      end
      assert_equal @profile.policy.name, profile1_result['name']
      assert_equal 1, profile1_result['totalHostCount']
      assert_equal 1, profile2_result['totalHostCount']
      assert_equal 1, profile1_result['testResultHostCount']
      assert_equal 1, profile1_result['compliantHostCount']
      assert_equal 1, profile1_result['unsupportedHostCount']
      assert_equal 1, profile1_result['hosts'].length
      assert_equal '4', profile1_result['osMinorVersion']
      assert_equal '7.4', profile1_result['osVersion']
      assert_not profile1_result['businessObjective']
    end
  end
end
