# frozen_string_literal: true

require 'test_helper'

# This class tests a "dummy" controller for authentication.
# Since testing Dummy controllers became quite complicated with
# ActionDispatch::IntegrationTest, it is testing the Profiles controller
# instead for the time being
class AuthenticationTest < ActionDispatch::IntegrationTest
  test 'rh-identity header not found' do
    get profiles_url
    assert_response :unauthorized
  end

  test 'error parsing rh-identity' do
    get profiles_url, headers: { 'X-RH-IDENTITY': 'this should be a hash' }
    assert_response :unauthorized
  end

  test 'account number not found, creates a new account' do
    encoded_header = Base64.encode64(
      {
        'identity':
        { 'account_number': '1234', 'id': users(:test).redhat_id }
      }.to_json
    )
    get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
    assert_response :success
    assert Account.find_by(account_number: '1234')
    assert_equal(
      User.find_by(redhat_id: users(:test).redhat_id).account.account_number,
      '1234'
    )
    assert_equal User.find_by(redhat_id: users(:test).redhat_id), User.current
  end

  test 'user not found, creates a new user' do
    encoded_header = Base64.encode64(
      {
        'identity':
        {
          'account_number': '1234',
          'id': '1234',
          'org_id': '29329',
          'email': 'a@b.com',
          'username': 'a@b.com',
          'first_name': 'a',
          'last_name': 'b',
          'is_active': true,
          'locale': 'en_US'
        }
      }.to_json
    )
    get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
    assert_response :success
    assert_equal User.find_by(redhat_id: '1234'), User.current
  end

  test 'user not found, creates a new account, username missing' do
    encoded_header = Base64.encode64(
      {
        'identity':
        {
          'account_number': '1234',
          'id': '1234',
          'org_id': '29329',
          'email': 'a@b.com',
          'first_name': 'a',
          'last_name': 'b',
          'is_active': true,
          'locale': 'en_US'
        }
      }.to_json
    )
    get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
    assert_response :unauthorized
    assert_not_equal User.current, User.find_by(redhat_id: '1234')
  end

  test 'successful authentication sets User.current' do
    encoded_header = Base64.encode64(
      {
        'identity':
        { 'account_number': '1234', 'id': users(:test).redhat_id }
      }.to_json
    )
    get profiles_url, headers: { 'X-RH-IDENTITY': encoded_header }
    assert_response :success
    assert_equal users(:test), User.current
  end
end
