# frozen_string_literal: true

require 'test_helper'

class RbacTest < ActiveSupport::TestCase
  setup do
    @account = FactoryBot.create(:account)
    FactoryBot.create(:user, account: @account)
  end

  context '#load_user_permissions' do
    should 'fail if ApiError is received' do
      RBACApiClient::AccessApi
        .any_instance
        .stubs(:get_principal_access)
        .raises(RBACApiClient::ApiError)
      assert_raise Rbac::AuthorizationError do
        Rbac.load_user_permissions(nil)
      end
    end

    should 'return users permissions' do
      stub_rbac_permissions('app:resource0:*', 'app:resource1:write')
      assert Rbac.load_user_permissions(@account.b64_identity)
    end
  end

  context '#load_inventory_groups' do
    should 'request users access to inventory groups' do
      permissions = [
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: %w[
                  78e3dc30-cec3-4b49-be2d-37482c74a9ac
                  79e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: [
                  nil # ungrouped hosts
                ],
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: 'inventory:groups:write', # entry with unverified permission is ignored
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: %w[
                  77e3dc30-cec3-4b49-be2d-37482c74a9ac
                  77e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: '80e3dc30-cec3-4b49-be2d-37482c74a9ad',
                operation: 'equal' # 'equal' is not a supported operation
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'foo.id', # entry with unverified key is ignored
                value: ['77e3dc30-cec3-4b49-be2d-37482c74a9ac'],
                operation: 'in'
              }
            )
          ]
        )
      ]

      assert_equal [
        '78e3dc30-cec3-4b49-be2d-37482c74a9ac',
        '79e3dc30-cec3-4b49-be2d-37482c74a9ad',
        Rbac::INVENTORY_UNGROUPED_ENTRIES
      ], Rbac.load_inventory_groups(permissions)
    end

    should 'return global access to groups' do
      permissions = [
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [] # empty array signes a global access
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: %w[
                  78e3dc30-cec3-4b49-be2d-37482c74a9ac
                  78e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            )
          ]
        )
      ]

      assert_equal Rbac::ANY, Rbac.load_inventory_groups(permissions)
    end

    should 'return global access to hosts' do
      permissions = [
        RBACApiClient::Access.new(
          permission: 'inventory:hosts:*', # inventory:hosts:*
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: %w[
                  78e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            )
          ]
        )
      ]

      assert_equal ['78e3dc30-cec3-4b49-be2d-37482c74a9ad'], Rbac.load_inventory_groups(permissions)
    end

    should 'ignore unverified keys or permissions' do
      permissions = [
        RBACApiClient::Access.new(
          permission: 'inventory:groups:write', # entry with unverified permission is ignored
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: %w[
                  77e3dc30-cec3-4b49-be2d-37482c74a9ac
                  77e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'foo.id', # entry with unverified key is ignored
                value: ['77e3dc30-cec3-4b49-be2d-37482c74a9ac'],
                operation: 'in'
              }
            )
          ]
        )
      ]

      assert_equal [], Rbac.load_inventory_groups(permissions)
    end

    should 'not respond to unexpected values' do
      permissions = [
        RBACApiClient::Access.new(
          permission: 'inventory:hosts:*', # inventory:hosts:*
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: nil,
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: nil, # nil
                operation: 'equal'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: nil, # nil
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: [], # []
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: [nil],
                operation: 'equal' # equal
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: [nil],
                operation: 'between' # between
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'groups.id', # groups.id
                value: 'not supported',
                operation: 'in'
              }
            )
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'groups.id', # groups.id
                value: 'some-id',
                operation: 'equal' # equal
              }
            )
          ]
        )
      ]

      assert_equal [], Rbac.load_inventory_groups(permissions)
    end

    should 'list ungrouped entries with groups' do
      permissions = [
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            RBACApiClient::ResourceDefinition.new(
              attribute_filter: {
                key: 'group.id',
                value: [nil, '80e3dc30-cec3-4b49-be2d-37482c74a9ad'],
                operation: 'in'
              }
            )
          ]
        )
      ]

      assert_equal [
        Rbac::INVENTORY_UNGROUPED_ENTRIES,
        '80e3dc30-cec3-4b49-be2d-37482c74a9ad'
      ], Rbac.load_inventory_groups(permissions)
    end
  end
end
