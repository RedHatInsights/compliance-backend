# frozen_string_literal: true

require 'test_helper'

# This class tests a "dummy" controller for authentication.
# Since testing Dummy controllers became quite complicated with
# ActionDispatch::IntegrationTest, it is testing the Profiles controller
# instead for the time being
class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    User.current = nil
  end

  context 'unauthorized access' do
    should 'rh-identity header not found' do
      get profiles_url
      assert_response :unauthorized
    end

    should 'error parsing rh-identity' do
      get profiles_url, headers: { 'X-RH-IDENTITY': 'this should be a hash' }
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
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
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
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :unauthorized
      assert_not User.current
    end

    should 'missing RBAC access for compliance' do
      RbacApi.any_instance.expects(:check_user)
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
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :forbidden
      assert_not User.current
    end
  end

  context 'successful login' do
    setup do
      RbacApi.any_instance.expects(:check_user).returns(true)
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
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
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
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
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
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
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
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
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
        get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
        assert_response :success
      ensure
        Settings.disable_rbac = 'false'
      end
    end
  end

  context 'disabled rbac via cert based auth' do
    should 'allow access to profiles#index' do
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': '1234'
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      RbacApi.expects(:new).never
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
    end

    should 'allow access to profiles#tailoring_file' do
      profiles(:one).update!(account: accounts(:one))
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': accounts(:one).account_number
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      RbacApi.expects(:new).never
      get tailoring_file_profile_url(profiles(:one)),
          headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
    end

    should 'disallow access to profiles#show' do
      RbacApi.any_instance.expects(:check_user)
      profiles(:one).update!(account: accounts(:one))
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': accounts(:one).account_number
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get profile_url(profiles(:one)),
          headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :forbidden
    end
  end
end
