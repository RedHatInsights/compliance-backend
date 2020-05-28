# frozen_string_literal: true

require 'test_helper'

class IdentityHeaderTest < ActiveSupport::TestCase
  setup do
    @b64_identity = {
      'entitlements': {
        'insights': {
          'is_entitled': true
        }
      },
      'identity': {
        'user': {},
        'account_number': '293912',
        'auth_type': 'basic-auth'
      }
    }
  end

  test 'is valid if insights entitlement provided' do
    assert IdentityHeader.new(
      Base64.strict_encode64(@b64_identity.to_json)
    ).valid?
  end

  test 'is not valid if insights entitlement not provided' do
    @b64_identity[:entitlements][:insights][:is_entitled] = false
    assert_not IdentityHeader.new(
      Base64.strict_encode64(@b64_identity.to_json)
    ).valid?
  end

  test 'properly detects cert-based auth from the auth_type' do
    assert_not IdentityHeader.new(
      Base64.strict_encode64(@b64_identity.to_json)
    ).cert_based?

    @b64_identity[:identity][:auth_type] = IdentityHeader::CERT_AUTH
    assert IdentityHeader.new(
      Base64.strict_encode64(@b64_identity.to_json)
    ).cert_based?
  end
end
