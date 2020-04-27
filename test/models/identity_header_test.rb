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
        'account_number': '293912'
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
end
