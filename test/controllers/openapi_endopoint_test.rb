# frozen_string_literal: true

require 'test_helper'

class OpenapiEndpointTest < ActionDispatch::IntegrationTest
  setup do
    stub_rbac_permissions(Rbac::COMPLIANCE_VIEWER, Rbac::INVENTORY_VIEWER)
  end

  test 'openapi success' do
    account = FactoryBot.create(:account)
    encoded_header = Base64.encode64(
      {
        'identity': {
          'auth_type': 'basic-auth',
          'org_id': account.org_id
        },
        'entitlements':
        {
          'insights': {
            'is_entitled': true
          }
        }
      }.to_json
    )
    get '/api/compliance/openapi.json', headers: { 'X-RH-IDENTITY': encoded_header }
    assert_response :success
  end
end
