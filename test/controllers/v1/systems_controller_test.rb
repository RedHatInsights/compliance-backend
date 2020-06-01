# frozen_string_literal: true

require 'test_helper'

module V1
  class SystemsControllerTest < ActionDispatch::IntegrationTest
    setup do
      SystemsController.any_instance.expects(:authenticate_user)
    end

    test 'index lists all systems' do
      SystemsController.any_instance.expects(:policy_scope).with(Host)
                       .returns(Host.all).at_least_once
      get v1_systems_url

      assert_response :success
    end

    test 'index accepts search' do
      SystemsController.any_instance.expects(:policy_scope).with(Host)
                       .returns(Host.all).at_least_once
      get v1_systems_url, params: { search: 'name=bar' }

      assert_response :success
    end

    test 'destroy hosts with authorized user' do
      User.current = users(:test)
      users(:test).update(account: accounts(:test))
      hosts(:one).update(account: accounts(:test))
      assert_difference('Host.count', -1) do
        delete "#{v1_systems_url}/#{hosts(:one).id}"
      end
      assert_response :success
    end

    test 'does not destroy hosts that do not belong to the user' do
      User.current = users(:test)
      users(:test).update(account: accounts(:test))
      hosts(:one).update(account: nil)
      assert_difference('Host.count', 0) do
        delete "#{v1_systems_url}/#{hosts(:one).id}"
      end
      assert_response :forbidden
    end
  end
end
