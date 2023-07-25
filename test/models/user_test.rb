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

  test 'bypasses RBAC when RBAC is disabled' do
    account = FactoryBot.create(:account)
    Settings.stubs(:disable_rbac).returns(true)
    user = FactoryBot.create(:user, account: account)

    assert_equal Rbac::ANY, user.inventory_groups
  end

  test 'bypasses RBAC when cert authenticated' do
    account = FactoryBot.create(:account)
    account.identity_header.content['identity']['auth_type'] = Insights::Api::Common::IdentityHeader::CERT_AUTH
    user = FactoryBot.create(:user, account: account)

    assert_equal [], user.inventory_groups
  end
end
