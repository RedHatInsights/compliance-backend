# frozen_string_literal: true

require 'test_helper'

require 'sidekiq/testing'
Sidekiq::Testing.fake!

class DeleteTestResultMutationTest < ActiveSupport::TestCase
  QUERY = <<-GRAPHQL
      mutation deleteTestResults($input: deleteTestResultsInput!) {
          deleteTestResults(input: $input) {
              profile {
                  id
              }
              testResults {
                  id
              }
          }
      }
  GRAPHQL

  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    @user = FactoryBot.create(:user)
    @profile = FactoryBot.create(:profile, account: @user.account)
    @host = FactoryBot.create(:host, org_id: @user.account.org_id)
    @tr = FactoryBot.create(
      :test_result,
      profile: @profile,
      host: @host
    )
    @profile.policy.update(hosts: [@host])
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  test 'delete a test result keeps the profile if part of a policy' do
    @profile.update(external: true)
    assert_audited_success 'Removed all user scoped test results', 'of policy', @profile.policy.id
    assert_difference('TestResult.count', -1) do
      assert_difference('Profile.count', 0) do
        result = Schema.execute(
          QUERY,
          variables: { input: {
            profileId: @profile.id
          } },
          context: { current_user: @user }
        ).dig('data', 'deleteTestResults')
        assert_equal @profile.id, result.dig('profile', 'id')
        assert_equal @tr.id, result.dig('testResults', 0, 'id')
      end
    end
  end

  test 'delete test results from initial policy profile deletes all results'\
       'in the policy' do
    profile2 = FactoryBot.create(
      :profile,
      account: @user.account,
      parent_profile: @profile.parent_profile,
      policy: @profile.policy,
      external: true
    )

    host2 = FactoryBot.create(:host, org_id: @user.account.org_id)
    profile2.policy.update(hosts: [@host, host2])
    FactoryBot.create(:test_result, profile: profile2, host: host2)

    assert_audited_success 'Removed all user scoped test results', 'of policy', @profile.policy.id
    assert_difference('TestResult.count', -2) do
      assert_difference('Profile.count', 0) do
        result = Schema.execute(
          QUERY,
          variables: { input: {
            profileId: @profile.id
          } },
          context: { current_user: @user }
        ).dig('data', 'deleteTestResults')
        assert_equal @profile.id, result.dig('profile', 'id')
        assert_includes result.dig('testResults').map { |tr| tr['id'] }, @tr.id
      end
    end
  end
end
