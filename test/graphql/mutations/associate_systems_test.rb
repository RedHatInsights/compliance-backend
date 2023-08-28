# frozen_string_literal: true

require 'test_helper'

class AssociateSystemsMutationTest < ActiveSupport::TestCase
  setup do
    PolicyHost.any_instance.stubs(:host_supported?).returns(true)
    @user = FactoryBot.create(:user)
    @profile = FactoryBot.create(:profile, account: @user.account, upstream: false)
    @host = FactoryBot.create(:host, org_id: @user.account.org_id)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)
    stub_supported_ssg([@host], [@profile.benchmark.version])
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

    assert_audited_success 'Updated system associaton of policy', @profile.policy.id
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
  end

  test 'only adds and removes accessible grouped hosts' do
    hosts = FactoryBot.create_list(:host, 4, :with_groups, org_id: @user.account.org_id, group_count: 1).map do |h|
      Host.find(h.id)
    end

    allowed_groups = hosts[0..1].map { |h| h.groups.first['id'] }
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ => [{
                            attribute_filter: {
                              key: 'group.id',
                              operation: 'in',
                              value: allowed_groups.to_json
                            }
                          }])

    @profile.policy.hosts = [hosts[0], hosts[2], hosts[3]]

    Schema.execute(
      QUERY,
      variables: { input: {
        id: @profile.id,
        systemIds: [hosts[1].id]
      } },
      context: { current_user: @user }
    )

    assert_equal Set.new(@profile.policy.reload.hosts),
                 Set.new(hosts[1..3])
  end

  test 'does not interfere with other policies' do
    host = Host.find(FactoryBot.create(:host, org_id: @user.account.org_id).id)
    hosts = FactoryBot.create_list(:host, 4, org_id: @user.account.org_id)

    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ)

    p2 = FactoryBot.create(:profile, account: @user.account, upstream: false)
    p2.policy.hosts = [host]

    Schema.execute(
      QUERY,
      variables: { input: {
        id: @profile.id,
        systemIds: hosts.map(&:id)
      } },
      context: { current_user: @user }
    )

    assert_includes p2.policy.hosts.reload, host
  end
end
