# frozen_string_literal: true

require 'test_helper'

# This class tests a "dummy" controller for authentication.
class AuthenticationTest < ActionController::TestCase
  # rubocop:disable Rails/ApplicationController
  class AuthenticatedMockController < ActionController::Base
    include Authentication

    def index
      user = User.current
      return false unless user

      render plain: user.account_number
    end

    def raising
      raise 'Error'
    end
  end
  # rubocop:enable Rails/ApplicationController

  MockedRoutes = ActionDispatch::Routing::RouteSet.new
  MockedRoutes.draw do
    ActiveSupport::Deprecation.silence do
      get ':controller(/:action)'
    end
  end

  setup do
    @routes = MockedRoutes
    @controller = AuthenticatedMockController.new
  end

  teardown do
    # expected to be cleared out by the middleware
    Thread.current[:audit_account_number] = nil
  end

  context 'unauthorized access' do
    should 'rh-identity header not found' do
      process_test
      assert_response :unauthorized
      assert_not User.current, 'current user must be reset after request'
    end

    should 'error parsing rh-identity' do
      process_test(headers: { 'X-RH-IDENTITY': 'this should be a hash' })
      assert_response :unauthorized
      assert_not User.current, 'current user must be reset after request'
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
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :unauthorized
      assert_not User.current, 'current user must be reset after request'
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
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :unauthorized
      assert_not User.current, 'current user must be reset after request'
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
      full_access_response = RBACApiClient::AccessPagination.new(
        data: [
          RBACApiClient::Access.new(
            permission: 'advisor:*:*',
            resource_definitions: nil
          )
        ]
      )
      RBACApiClient::AccessApi
        .any_instance
        .stubs(:get_principal_access)
        .returns(full_access_response)
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :forbidden
      assert_not User.current, 'current user must be reset after request'
    end
  end

  context 'successful login' do
    setup do
      full_access_response = RBACApiClient::AccessPagination.new(
        data: [
          RBACApiClient::Access.new(
            permission: 'compliance:*:*',
            resource_definitions: nil
          )
        ]
      )
      RBACApiClient::AccessApi
        .any_instance
        .stubs(:get_principal_access)
        .returns(full_access_response)
    end

    should 'account number not found, creates a new account' do
      encoded_header = Base64.encode64(
        {
          'identity': {
            'account_number': '1234',
            'user': {
              'username': 'username',
              'is_internal': true
            }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :success
      assert_equal '1234', response.body
      assert Account.find_by(account_number: '1234')
      assert_equal(
        Account.find_by(account_number: '1234').account_number,
        '1234'
      )
      assert Account.find_by(account_number: '1234').is_internal
      assert_not User.current, 'current user must be reset after request'
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
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :success
      assert_equal '1234', response.body
      assert_equal(
        Account.find_by(account_number: '1234').account_number,
        '1234'
      )
      assert_not User.current, 'current user must be reset after request'
    end

    should 'account found, is_internal unset, updates it' do
      FactoryBot.create(:account, account_number: '1234')
      assert_nil Account.find_by(account_number: '1234').is_internal

      encoded_header = Base64.encode64(
        {
          'identity':
          {
            'account_number': '1234',
            'user': {
              'username': 'username',
              'is_internal': false
            }
          },
          'entitlements':
          {
            'insights': {
              'is_entitled': true
            }
          }
        }.to_json
      )

      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :success
      assert_equal '1234', response.body
      assert_equal false, Account.find_by(account_number: '1234').is_internal
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
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :success
      assert_equal '1234', response.body
      assert_not User.current, 'current user must be reset after request'
    end

    should 'set User.current' do
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
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :success
      assert_equal '1234', response.body
      assert_equal(
        Account.find_by(account_number: '1234').account_number,
        '1234'
      )
      assert_not User.current, 'current user must be reset after request'
    end

    should 'set audit account context' do
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
      Insights::API::Common::AuditLog.expects(:audit_with_account).with('1234')
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :success
      assert_not User.current, 'current user must be reset after request'
    end

    should 'reset current user after an exeption' do
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
      assert_raises StandardError do
        process_test(action: 'raising',
                     headers: { 'X-RH-IDENTITY': encoded_header })
      end
      assert_not User.current, 'current user must be reset after request'
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
        process_test(headers: { 'X-RH-IDENTITY': encoded_header })
        assert_response :success
        assert_equal '1234', response.body
        assert_not User.current, 'current user must be reset after request'
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
      AuthenticatedMockController.any_instance
                                 .stubs(:valid_cert_endpoint?)
                                 .returns(true)
      HostInventoryApi.any_instance.expects(:hosts)
                      .raises(Faraday::Error.new(''))
      process_test(headers: { 'X-RH-IDENTITY': encoded_header })
      assert_response :forbidden
      assert_not User.current, 'current user must be reset after request'
    end
  end

  private

  def process_test(params = {})
    headers = params.delete(:headers)
    action_name = params.delete(:action) || 'index'

    if headers

      @request = ActionDispatch::TestRequest.create
      headers.each { |key, val| @request.headers[key] = val }
    end

    process(action_name, **params)
  end
end
