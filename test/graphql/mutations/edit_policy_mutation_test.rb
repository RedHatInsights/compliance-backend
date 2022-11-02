# frozen_string_literal: true

require 'test_helper'

class EditPolicyMutationTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @profile = FactoryBot.create(:profile, account: @user.account)
    @host = FactoryBot.create(:host, org_id: @user.account.org_id)
    @tr = FactoryBot.create(:test_result, host: @host, profile: @profile)
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    @profile.policy.update(hosts: [@host])
    @bo = FactoryBot.create(:business_objective)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  test 'query host owned by the user' do
    query = <<-GRAPHQL
        mutation updateProfile($input: UpdateProfileInput!) {
            updateProfile(input: $input) {
                profile {
                    id,
                    complianceThreshold,
                    businessObjectiveId
                }
            }
        }
    GRAPHQL

    assert_nil @profile.policy.business_objective

    assert_audited_success 'Updated profile', @profile.id, @profile.policy.id
    result = Schema.execute(
      query,
      variables: { input: {
        id: @profile.id,
        complianceThreshold: 80.0,
        businessObjectiveId: @bo.id
      } },
      context: { current_user: @user }
    )['data']['updateProfile']['profile']

    assert_equal @bo.id, result['businessObjectiveId']
    assert_equal 80.0, result['complianceThreshold']
  end

  test 'unset the business objective' do
    query = <<-GRAPHQL
        mutation updateProfile($input: UpdateProfileInput!) {
            updateProfile(input: $input) {
                profile {
                    businessObjectiveId
                }
            }
        }
    GRAPHQL

    @profile.policy.update(business_objective: @bo)

    assert_audited_success 'Autoremoved orphaned Business Objectives', @bo.id
    assert_audited_success 'Updated profile', @profile.id, @profile.policy.id
    Schema.execute(
      query,
      variables: { input: {
        id: @profile.id,
        businessObjectiveId: nil
      } },
      context: { current_user: @user }
    )['data']['updateProfile']['profile']

    assert_nil @profile.policy.reload.business_objective
  end
end
