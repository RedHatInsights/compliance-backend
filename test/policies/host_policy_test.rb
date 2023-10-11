# frozen_string_literal: true

require 'test_helper'

class HostPolicyTest < ActiveSupport::TestCase
  test 'only hosts matching the account are accessible' do
    user = FactoryBot.create(:user)
    own_host_in_group = Host.find(
      FactoryBot.create(:host, :with_groups, group_count: 1, org_id: user.account.org_id).id
    )
    own_host_ungrouped = Host.find(
      FactoryBot.create(:host, org_id: user.account.org_id).id
    )
    a = FactoryBot.create(:account)
    foreign_host = Host.find(FactoryBot.create(
      :host,
      org_id: a.org_id
    ).id)

    own_host_outside_group = Host.find(
      FactoryBot.create(:host, :with_groups, group_count: 1, org_id: user.account.org_id).id
    )

    stub_rbac_permissions(
      Rbac::INVENTORY_HOSTS_READ => [{
        attribute_filter: {
          key: 'group.id',
          operation: 'in',
          value: [own_host_in_group.groups.first['id'], nil]
        }
      }]
    )

    [own_host_in_group, own_host_ungrouped].each do |host|
      assert Pundit.authorize(user, host, :index?)
      assert Pundit.authorize(user, host, :show?)
      assert_includes Pundit.policy_scope(user, Host), host
    end

    [foreign_host, own_host_outside_group].each do |host|
      assert_raises(Pundit::NotAuthorizedError) do
        Pundit.authorize(user, host, :index?)
      end

      assert_raises(Pundit::NotAuthorizedError) do
        Pundit.authorize(user, host, :show?)
      end

      assert_not_includes Pundit.policy_scope(user, Host), host
    end
  end
end
