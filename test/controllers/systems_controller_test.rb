# frozen_string_literal: true

require 'test_helper'

class SystemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    SystemsController.any_instance.expects(:authenticate_user)
    SystemsController.any_instance.expects(:policy_scope).with(Host)
                     .returns(Host.all).at_least_once
  end

  test 'index lists all systems' do
    get systems_url

    assert_response :success
  end

  test 'index accepts search' do
    get systems_url, params: { search: 'name=bar' }

    assert_response :success
  end
end
