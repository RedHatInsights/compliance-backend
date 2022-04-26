# frozen_string_literal: true

require 'test_helper'

class AssociateSystemsMutationTest < ActiveSupport::TestCase
  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    @user = FactoryBot.create(:user)
    @profile = FactoryBot.create(:profile, account: @user.account)
    @host = FactoryBot.create(:host, account: @user.account.account_number, org_id: @user.account.org_id)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
    stub_supported_ssg([@host])
  end

  QUERY = <<-GRAPHQL
     mutation associateSystems($input: associateSystemsInput!) {
        associateSystems(input: $input) {
           profile {
               id
           }
           profiles {
               id
           }
        }
     }
  GRAPHQL

  test 'provide all required arguments' do
    assert_empty @profile.assigned_hosts

    result = Schema.execute(
      QUERY,
      variables: { input: {
        id: @profile.id,
        systemIds: [@host.id]
      } },
      context: { current_user: @user }
    )

    assert_equal(
      result['data']['associateSystems']['profile']['id'],
      @profile.id
    )

    assert_equal(
      result['data']['associateSystems']['profiles'],
      [{ 'id' => @profile.id }]
    )

    assert_equal Set.new(@profile.policy.reload.hosts),
                 Set.new([Host.find(@host.id)])
  end

  test 'removes systems from a profile' do
    @profile.policy.hosts = [@host]
    FactoryBot.create(
      :test_result,
      profile: @profile,
      host: @host
    )
    assert_not_empty @profile.hosts

    result = Schema.execute(
      QUERY,
      variables: { input: {
        id: @profile.id,
        systemIds: []
      } },
      context: { current_user: @user }
    )

    assert_equal(
      result['data']['associateSystems']['profile']['id'],
      @profile.id
    )

    assert_equal(
      result['data']['associateSystems']['profiles'],
      [{ 'id' => @profile.id }]
    )

    assert_empty @profile.policy.reload.hosts
    assert_audited 'Updated system associaton of policy'
    assert_audited @profile.policy.id
  end
end
