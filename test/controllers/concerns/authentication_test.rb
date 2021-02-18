# frozen_string_literal: true

require 'test_helper'

# This class tests a "dummy" controller for authentication.
class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    User.current = nil
    ApplicationController.any_instance.stubs(:index).returns('Response Body')
    Rails.application.routes.draw do
      root 'application#index'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  context 'unauthorized access' do
    should 'rh-identity header not found' do
      get '/'
      assert_response :unauthorized
    end

    should 'error parsing rh-identity' do
      get '/', headers: { 'X-RH-IDENTITY': 'this should be a hash' }
      assert_response :unauthorized
    end

    should 'missing entitlement info completely' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'user': { 'username': 'username' }
          }
        }.to_json
      )
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :unauthorized
      assert_not User.current
    end

    should 'missing insights entitlement' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'user': { 'username': 'username' }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': false
            }
          }
        }.to_json
      )
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :unauthorized
      assert_not User.current
    end

    should 'missing RBAC access for compliance' do
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': '1234',
            'user': { 'username': 'username' }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      rbac_request = OpenStruct.new(body: {
        'data': [{ 'permission': 'advisor:*:*' }]
      }.to_json)
      ::Faraday::Connection.any_instance.expects(:get).returns(rbac_request)
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :forbidden
      assert_not User.current
    end
  end

  context 'successful login' do
    setup do
      rbac_request = OpenStruct.new(body: {
        'data': [{ 'permission': 'compliance:*:*' }]
      }.to_json)
      ::Faraday::Connection.any_instance.expects(:get).returns(rbac_request)
    end

    should 'account number not found, creates a new account' do
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': '1234',
            'user': { 'username': 'username' }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
      assert Account.find_by(account_number: '1234')
      assert_equal(
        Account.find_by(account_number: '1234').account_number,
        '1234'
      )
      assert_equal Account.find_by(account_number: '1234'), User.current.account
    end

    should 'user not found, creates a new user' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'user': { 'username': 'username' }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
      assert_equal Account.find_by(account_number: '1234'), User.current.account
    end

    should 'user not found, creates a new account, username missing' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'user': { 'username': 'username' }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
      assert_not_nil User.current
    end

    should 'successful authentication sets User.current' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'user': { 'username': 'username' }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
      assert_equal Account.find_by(account_number: '1234'), User.current.account
    end
  end

  context 'disable rbac' do
    should 'allow access when RBAC is disabled' do
      begin
        encoded_header = Base64.encode64(
          {
            'identity': {
              'account_number': '1234',
              'user': { 'username': 'username' }
            },
            'entitlements':
            {
              'insights': {
                'is_entitled': true
              }
            }
          }.to_json
        )
        Settings.disable_rbac = 'true'
        RbacApi.expects(:new).never
        get '/', headers: { 'X-RH-IDENTITY': encoded_header }
        assert_response :success
      ensure
        Settings.disable_rbac = 'false'
      end
    end
  end

  context 'disabled rbac via cert based auth' do
    should 'disallows access when inventory errors' do
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': '1234',
            'auth_type': IdentityHeader::CERT_AUTH
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      ApplicationController.any_instance.stubs(:valid_cert_endpoint?).returns(true)
      HostInventoryApi.any_instance.expects(:hosts)
                      .raises(Faraday::Error.new(''))
      RbacApi.expects(:new).never
      get '/', headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :forbidden
    end
  end
end
