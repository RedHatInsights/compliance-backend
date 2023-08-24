# frozen_string_literal: true

require 'test_helper'

class PolicyHostPolicyTest < ActiveSupport::TestCase
  test 'only hosts matching the account are accessible' do
    user = FactoryBot.create(:user)
    policy = FactoryBot.create(:profile, upstream: false, account: user.account).policy

    own_host_in_group = Host.find(
      FactoryBot.create(:host, :with_groups, group_count: 1, org_id: user.account.org_id).id
    )

    own_host_ungrouped = Host.find(
      FactoryBot.create(:host, org_id: user.account.org_id).id
    )

    own_host_outside_group = Host.find(
      FactoryBot.create(:host, :with_groups, group_count: 1, org_id: user.account.org_id).id
    )

    stub_supported_ssg(Host.all.to_a, [policy.profiles.first.benchmark.version])
    stub_rbac_permissions(Rbac::INVENTORY_HOSTS_READ)
    policy.update_hosts(Host.pluck(:id), user)
    user.instance_variable_set(:@rbac_permissions, nil)
    user.instance_variable_set(:@inventory_groups, nil)

    stub_rbac_permissions(
      Rbac::INVENTORY_HOSTS_READ => [{
        attribute_filter: {
          key: 'group.id',
          operation: 'in',
          value: [own_host_in_group.groups.first['id'], nil].to_json
        }
      }]
    )

    [own_host_in_group, own_host_ungrouped].each do |host|
      ph = host.policy_hosts.first
      assert Pundit.authorize(user, ph, :index?)
      assert Pundit.authorize(user, ph, :show?)
      assert_includes Pundit.policy_scope(user, PolicyHost), ph
    end

    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(user, own_host_outside_group.policy_hosts.first, :index?)
    end

    assert_raises(Pundit::NotAuthorizedError) do
      Pundit.authorize(user, own_host_outside_group.policy_hosts.first, :show?)
    end

    assert_not_includes Pundit.policy_scope(user, PolicyHost), own_host_outside_group.policy_hosts.first
  end
end
