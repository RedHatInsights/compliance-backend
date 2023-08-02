# frozen_string_literal: true

require 'test_helper'

class AssociateProfilesMutationTest < ActiveSupport::TestCase
  QUERY = <<-GRAPHQL
     mutation associateProfiles($input: associateProfilesInput!) {
        associateProfiles(input: $input) {
           system {
               id
               name
           }
        }
     }
  GRAPHQL

  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    @user = FactoryBot.create(:user)
    @profiles = FactoryBot.create_list(:profile, 2, account: @user.account)
    @host = FactoryBot.create(:host, org_id: @user.account.org_id)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
  end

  test 'provide all required arguments' do
    assert_empty @host.policies

    Schema.execute(
      QUERY,
      variables: { input: {
        id: @host.id,
        profileIds: @profiles.map(&:id)
      } },
      context: { current_user: @user }
    )['data']['associateProfiles']['system']

    assert_equal Set.new(@host.reload.policies),
                 Set.new(@profiles.map(&:policy))
  end

  test 'external profiles are kept after associating internal profiles' do
    assert_audited_success 'Associated host', @host.id, *@profiles.map(&:policy_id)
    Schema.execute(
      QUERY,
      variables: { input: {
        id: @host.id,
        profileIds: @profiles.map(&:id)
      } },
      context: { current_user: @user }
    )['data']['associateProfiles']['system']

    assert_equal Set.new(@profiles.map(&:policy)),
                 Set.new(@host.reload.policies)
  end
end
