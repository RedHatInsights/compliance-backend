# frozen_string_literal: true

require 'test_helper'

class RbacApiTest < ActiveSupport::TestCase
  context 'check_user' do
    setup do
      @rbac_api = RbacApi.new('')
      @no_data_response = OpenStruct.new(body: { 'data' => [] }.to_json)
      @no_compliance_access_response = OpenStruct.new(
        body: { 'data' => [{ 'permission' => 'remediations:*:*' }] }.to_json
      )
      @compliance_access_response = OpenStruct.new(
        body: { 'data' => [{ 'permission' => 'compliance:*:*' }] }.to_json
      )
    end

    should 'return false during rbac/faraday error' do
      @rbac_api.expects(:access_check_response)
               .raises(Faraday::ClientError.new(''))

      assert_not @rbac_api.check_user
    end

    should 'return false when rbac shows no access' do
      @rbac_api.expects(:access_check_response)
               .returns(@no_data_response)

      assert_not @rbac_api.check_user
    end

    should 'return false when rbac shows no access to compliance' do
      @rbac_api.expects(:access_check_response)
               .returns(@no_compliance_access_response)

      assert_not @rbac_api.check_user
    end

    should 'return true when rbac shows access to compliance' do
      @rbac_api.expects(:access_check_response)
               .returns(@compliance_access_response)

      assert @rbac_api.check_user
    end
  end
end
