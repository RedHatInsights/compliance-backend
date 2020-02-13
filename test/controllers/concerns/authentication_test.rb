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
            'type': 'User',
            'user': {
              'email': 'a@b.com',
              'first_name': 'a',
              'last_name': 'b',
              'is_active': true,
              'locale': 'en_US'
            },
            'internal': {
              'org_id': '29329'
            }
          }
        }.to_json
      )
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :unauthorized
      assert_not User.current
    end

    should 'missing smart_management entitlement' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'type': 'User',
            'user': {
              'email': 'a@b.com',
              'first_name': 'a',
              'last_name': 'b',
              'is_active': true,
              'locale': 'en_US'
            },
            'internal': {
              'org_id': '29329'
            }
          },
          'entitlements':
          {
            'smart_management': {
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
      RbacApi.any_instance.expects(:check_user).returns(false)
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': '1234',
            'user': {
              'username': 'shoulduser'
            }
          },
          'entitlements':
          {
            'smart_management': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :unauthorized
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
            'user': {
              'username': 'shoulduser'
            }
          },
          'entitlements':
          {
            'smart_management': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
      assert Account.find_by(account_number: '1234')
      assert_equal(
        User.find_by(username: 'shoulduser').account.account_number,
        '1234'
      )
      assert_equal User.find_by(username: 'shoulduser'), User.current
    end

    should 'user not found, creates a new user' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'type': 'User',
            'user': {
              'email': 'a@b.com',
              'username': 'a@b.com',
              'first_name': 'a',
              'last_name': 'b',
              'is_active': true,
              'locale': 'en_US'
            },
            'internal': {
              'org_id': '29329'
            }
          },
          'entitlements':
          {
            'smart_management': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
      assert_equal User.find_by(username: 'a@b.com'), User.current
    end

    should 'user not found, creates a new account, username missing' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'type': 'User',
            'user': {
              'email': 'a@b.com',
              'first_name': 'a',
              'last_name': 'b',
              'is_active': true,
              'locale': 'en_US'
            },
            'internal': {
              'org_id': '29329'
            }
          },
          'entitlements':
          {
            'smart_management': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :unauthorized
      assert_not User.current
    end

    should 'successful authentication sets User.current' do
      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'user': {
              'username': 'fakeuser'
            }
          },
          'entitlements':
          {
            'smart_management': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
      assert_response :success
      assert_equal User.find_by(username: 'fakeuser'), User.current
    end
  end

  context 'disable rbac' do
    should 'allow access when RBAC is disabled' do
      begin
        encoded_header = Base64.encode64(
          {
            'identity': {
              'account_number': '1234',
              'user': {
                'username': 'shoulduser'
              }
            },
            'entitlements':
            {
              'smart_management': {
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
end
