# frozen_string_literal: true

require 'test_helper'

class SystemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SystemsController.any_instance.expects(:authenticate_user)
  end

  test 'index lists all systems' do
    SystemsController.any_instance.expects(:policy_scope).with(Host)
    get systems_url

    assert_response :success
  end

  test 'index accepts search' do
    scope = mock('scope')
    SystemsController.any_instance.expects(:policy_scope).with(Host).returns(scope)
    scope.expects(:search_for).with('foo=bar')

    get systems_url, params: {search: 'foo=bar'}

    assert_response :success
  end
end
