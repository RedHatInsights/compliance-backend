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
          resource_definitions: nil
        ),
        RBACApiClient::Access.new(
          permission: 'app:resource1:write',
          resource_definitions: nil
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
end
