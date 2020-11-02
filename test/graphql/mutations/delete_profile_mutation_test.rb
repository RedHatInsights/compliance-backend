# frozen_string_literal: true

require 'test_helper'

class DeleteProfileMutationTest < ActiveSupport::TestCase
  test 'delete a profile provided an ID' do
    query = <<-GRAPHQL
        mutation DeleteProfile($input: deleteProfileInput!) {
            deleteProfile(input: $input) {
                profile {
                    id
                }
            }
        }
    GRAPHQL

    users(:test).update account: accounts(:test)
    profiles(:one).update(account: accounts(:test))

    assert_difference('Profile.count', -1) do
      result = Schema.execute(
        query,
        variables: { input: {
          id: profiles(:one).id
        } },
        context: { current_user: users(:test) }
      )['data']['deleteProfile']['profile']
      assert_equal profiles(:one).id, result['id']
    end
  end

  test 'deleting internal profile detroys its policy with profiles' do
    query = <<-GRAPHQL
        mutation DeleteProfile($input: deleteProfileInput!) {
            deleteProfile(input: $input) {
                profile {
                    id
                }
            }
        }
    GRAPHQL

    users(:test).update account: accounts(:test)
    profiles(:one).update!(account: accounts(:test),
                           policy_id: policies(:one).id)

    profiles(:two).update!(account: accounts(:test),
                           external: true,
                           policy_id: policies(:one).id)

    profile_id = profiles(:one).id
    assert_difference('Profile.count' => -2, 'Policy.count' => -1) do
      result = Schema.execute(
        query,
        variables: { input: {
          id: profile_id
        } },
        context: { current_user: users(:test) }
      )['data']['deleteProfile']['profile']
      assert_equal profile_id, result['id']
    end
  end

  test 'deleting other policy profile keeps policy and its profiles' do
    query = <<-GRAPHQL
        mutation DeleteProfile($input: deleteProfileInput!) {
            deleteProfile(input: $input) {
                profile {
                    id
                }
            }
        }
    GRAPHQL

    users(:test).update account: accounts(:test)
    profiles(:one).update!(account: accounts(:test),
                           policy_id: policies(:one).id)

    profiles(:two).update!(account: accounts(:test),
                           external: true,
                           policy_id: policies(:one).id)

    profile_id = profiles(:two).id
    assert_difference('Profile.count' => -1, 'Policy.count' => 0) do
      result = Schema.execute(
        query,
        variables: { input: {
          id: profile_id
        } },
        context: { current_user: users(:test) }
      )['data']['deleteProfile']['profile']
      assert_equal profile_id, result['id']
    end
  end
end
