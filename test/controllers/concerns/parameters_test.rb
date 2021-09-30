# frozen_string_literal: true

require 'test_helper'

# Tests for the parameters concern
class ParametersTest < ActionDispatch::IntegrationTest
  def authenticate
    V1::ProfilesController.any_instance.stubs(:authenticate_user).yields
    User.current = FactoryBot.create(:user)
  end

  test 'validates relationships param to be a boolean' do
    authenticate

    get profiles_url(relationships: 'foo')
    assert_response :unprocessable_entity

    get profiles_url(relationships: 12_345)
    assert_response :unprocessable_entity

    get profiles_url(relationships: true)
    assert_response :success

    get profiles_url(relationships: false)
    assert_response :success
  end

  test 'defaults relationships param to be true' do
    authenticate

    get profiles_url(relationships: false)
    assert_equal false, json_body['meta']['relationships']

    get profiles_url
    assert_equal true, json_body['meta']['relationships']
  end
end
