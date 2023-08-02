# frozen_string_literal: true

require 'test_helper'

class DeleteProfileMutationTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @profile = FactoryBot.create(:profile, account: @user.account)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
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
    assert_audited_success 'Removed profile', @profile.id
    assert_audited_success('Autoremoved policy').twice
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
  end

  test 'deleting internal profile detroys its policy with profiles' do
    FactoryBot.create(
      :profile,
      account: @user.account,
      policy: @profile.policy,
      external: true
    )

    assert_audited_success 'Removed profile', @profile.id
    assert_audited_success 'Autoremoved policy', @profile.policy.id, 'with the initial/main profile'
    assert_audited_success 'Autoremoved policy', 'with the last profile'
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
  end

  test 'deleting other policy profile keeps policy and its profiles' do
    second = FactoryBot.create(
      :profile,
      account: @user.account,
      policy: @profile.policy,
      external: true
    )

    assert_audited_success 'Removed profile', @profile.policy.id
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
  end

  context 'unauthorized user' do
    setup do
      stub_rbac_permissions(Rbac::COMPLIANCE_VIEWER, Rbac::INVENTORY_HOSTS_READ)
    end

    should 'have the delete action rejected' do
      second = FactoryBot.create(
        :profile,
        account: @user.account,
        policy: @profile.policy,
        external: true
      )

      assert_raises(GraphQL::UnauthorizedError, 'User is not authorized to access this action.') do
        Schema.execute(
          QUERY,
          variables: { input: {
            id: second.id
          } },
          context: { current_user: @user }
        )
      end
    end
  end
end
