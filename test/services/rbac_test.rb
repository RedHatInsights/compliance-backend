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
        .returns(fake_rbac_api_response)
      assert Rbac.load_user_permissions(@account.b64_identity)
    end
  end
end
