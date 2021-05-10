# frozen_string_literal: true

require 'test_helper'

class DeleteProfileMutationTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @profile = FactoryBot.create(:profile, account: @user.account)
  end

  QUERY = <<-GRAPHQL
      mutation DeleteProfile($input: deleteProfileInput!) {
          deleteProfile(input: $input) {
              profile {
                  id
              }
          }
      }
  GRAPHQL

  test 'delete a profile provided an ID' do
    assert_difference('Profile.count', -1) do
      result = Schema.execute(
        QUERY,
        variables: { input: {
          id: @profile.id
        } },
        context: { current_user: @user }
      )['data']['deleteProfile']['profile']
      assert_equal @profile.id, result['id']
    end
    assert_audited 'Removed profile'
    assert_audited @profile.id
  end

  test 'deleting internal profile detroys its policy with profiles' do
    FactoryBot.create(
      :profile,
      account: @user.account,
      policy: @profile.policy,
      external: true
    )

    assert_difference('Profile.count' => -2, 'Policy.count' => -1) do
      result = Schema.execute(
        QUERY,
        variables: { input: {
          id: @profile.id
        } },
        context: { current_user: @user }
      )['data']['deleteProfile']['profile']
      assert_equal @profile.id, result['id']
    end
    assert_audited 'Removed profile'
    assert_audited @profile.id
    assert_audited @profile.policy.id
    assert_audited 'Autoremoved policy'
    assert_audited 'with the initial/main profile'
  end

  test 'deleting other policy profile keeps policy and its profiles' do
    second = FactoryBot.create(
      :profile,
      account: @user.account,
      policy: @profile.policy,
      external: true
    )

    assert_difference('Profile.count' => -1, 'Policy.count' => 0) do
      result = Schema.execute(
        QUERY,
        variables: { input: {
          id: second.id
        } },
        context: { current_user: @user }
      )['data']['deleteProfile']['profile']
      assert_equal second.id, result['id']
    end
    assert_audited 'Removed profile'
    assert_audited @profile.policy.id
  end
end
