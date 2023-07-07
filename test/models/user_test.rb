# frozen_string_literal: true

require 'test_helper'
require 'insights-rbac-api-client'

class UserTest < ActiveSupport::TestCase
  should validate_uniqueness_of(:username).scoped_to(:account_id)
  should validate_presence_of :username
  should belong_to :account

  test 'can test RBAC resources authorization' do
    account = FactoryBot.create(:account)
    current_user = FactoryBot.create(:user, account: account)
    fake_rbac_api_response = RBACApiClient::AccessPagination.new(
      data: [
        RBACApiClient::Access.new(
          permission: 'app:resource0:*',
          resource_definitions: []
        ),
        RBACApiClient::Access.new(
          permission: 'app:resource1:write',
          resource_definitions: []
        )
      ]
    )
    RBACApiClient::AccessApi
      .any_instance
      .expects(:get_principal_access)
      .once
      .returns(fake_rbac_api_response)

    assert current_user.authorized_to?('app:resource0:*')
    assert current_user.authorized_to?('app:resource0:destroy')
    assert current_user.authorized_to?('app:resource1:write')
    assert_not current_user.authorized_to?('app:*:link')
    assert_not current_user.authorized_to?('app:*:*')
    assert_not current_user.authorized_to?('app:resource1:read')
    assert_not current_user.authorized_to?('app:resource1:*')
  end

  test 'can request users access to inventory groups' do
    account = FactoryBot.create(:account)
    current_user = FactoryBot.create(:user, account: account)
    fake_rbac_api_response = RBACApiClient::AccessPagination.new(
      data: [
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: %w[
                  78e3dc30-cec3-4b49-be2d-37482c74a9ac
                  79e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: [
                  nil # ungrouped hosts
                ],
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: 'inventory:groups:write', # entry with unverified permission is ignored
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: %w[
                  77e3dc30-cec3-4b49-be2d-37482c74a9ac
                  77e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: '80e3dc30-cec3-4b49-be2d-37482c74a9ad',
                operation: 'equal' # 'equal' is not a supported operation
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'foo.id', # entry with unverified key is ignored
                value: ['77e3dc30-cec3-4b49-be2d-37482c74a9ac'],
                operation: 'in'
              }
            }
          ]
        )
      ]
    )
    RBACApiClient::AccessApi
      .any_instance
      .expects(:get_principal_access)
      .once
      .returns(fake_rbac_api_response)

    assert_equal [
      '78e3dc30-cec3-4b49-be2d-37482c74a9ac',
      '79e3dc30-cec3-4b49-be2d-37482c74a9ad',
      Rbac::INVENTORY_UNGROUPED_ENTRIES
    ], current_user.inventory_groups
  end

  test 'returns global access to groups' do
    account = FactoryBot.create(:account)
    current_user = FactoryBot.create(:user, account: account)
    fake_rbac_api_response = RBACApiClient::AccessPagination.new(
      data: [
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [] # empty array signes a global access
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: %w[
                  78e3dc30-cec3-4b49-be2d-37482c74a9ac
                  78e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            }
          ]
        )
      ]
    )
    RBACApiClient::AccessApi
      .any_instance
      .expects(:get_principal_access)
      .once
      .returns(fake_rbac_api_response)

    assert_equal Rbac::ANY, current_user.inventory_groups
  end

  test 'global access to hosts' do
    account = FactoryBot.create(:account)
    current_user = FactoryBot.create(:user, account: account)
    fake_rbac_api_response = RBACApiClient::AccessPagination.new(
      data: [
        RBACApiClient::Access.new(
          permission: 'inventory:hosts:*', # inventory:hosts:*
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: %w[
                  78e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            }
          ]
        )
      ]
    )
    RBACApiClient::AccessApi
      .any_instance
      .expects(:get_principal_access)
      .once
      .returns(fake_rbac_api_response)

    assert_equal ['78e3dc30-cec3-4b49-be2d-37482c74a9ad'], current_user.inventory_groups
  end

  test 'ignores unverified keys or permissions' do
    account = FactoryBot.create(:account)
    current_user = FactoryBot.create(:user, account: account)
    fake_rbac_api_response = RBACApiClient::AccessPagination.new(
      data: [
        RBACApiClient::Access.new(
          permission: 'inventory:groups:write', # entry with unverified permission is ignored
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: %w[
                  77e3dc30-cec3-4b49-be2d-37482c74a9ac
                  77e3dc30-cec3-4b49-be2d-37482c74a9ad
                ],
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'foo.id', # entry with unverified key is ignored
                value: ['77e3dc30-cec3-4b49-be2d-37482c74a9ac'],
                operation: 'in'
              }
            }
          ]
        )
      ]
    )
    RBACApiClient::AccessApi
      .any_instance
      .expects(:get_principal_access)
      .once
      .returns(fake_rbac_api_response)

    assert_equal [], current_user.inventory_groups
  end

  test 'does not respond to unexpected values' do
    account = FactoryBot.create(:account)
    current_user = FactoryBot.create(:user, account: account)
    fake_rbac_api_response = RBACApiClient::AccessPagination.new(
      data: [
        RBACApiClient::Access.new(
          permission: 'inventory:hosts:*', # inventory:hosts:*
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: nil,
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: nil, # nil
                operation: 'equal'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: nil, # nil
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: [], # []
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: [nil],
                operation: 'equal' # equal
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: [nil],
                operation: 'between' # between
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'groups.id', # groups.id
                value: 'not supported',
                operation: 'in'
              }
            }
          ]
        ),
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'groups.id', # groups.id
                value: 'some-id',
                operation: 'equal' # equal
              }
            }
          ]
        )
      ]
    )
    RBACApiClient::AccessApi
      .any_instance
      .expects(:get_principal_access)
      .once
      .returns(fake_rbac_api_response)

    assert_equal [], current_user.inventory_groups
  end

  test 'ungrouped entries can be listed with a group' do
    account = FactoryBot.create(:account)
    current_user = FactoryBot.create(:user, account: account)
    fake_rbac_api_response = RBACApiClient::AccessPagination.new(
      data: [
        RBACApiClient::Access.new(
          permission: Rbac::INVENTORY_HOSTS_READ,
          resource_definitions: [
            {
              attributeFilter: {
                key: 'group.id',
                value: [nil, '80e3dc30-cec3-4b49-be2d-37482c74a9ad'],
                operation: 'in'
              }
            }
          ]
        )
      ]
    )
    RBACApiClient::AccessApi
      .any_instance
      .expects(:get_principal_access)
      .once
      .returns(fake_rbac_api_response)

    assert_equal [
      Rbac::INVENTORY_UNGROUPED_ENTRIES,
      '80e3dc30-cec3-4b49-be2d-37482c74a9ad'
    ], current_user.inventory_groups
  end
end
