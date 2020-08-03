# frozen_string_literal: true

require 'test_helper'

module V1
  class SystemsControllerTest < ActionDispatch::IntegrationTest
    setup do
      SystemsController.any_instance.expects(:authenticate_user)
    end

    context 'index' do
      should 'lists all systems' do
        SystemsController.any_instance.expects(:policy_scope).with(Host)
                         .returns(Host.all).at_least_once
        get v1_systems_url

        assert_response :success
      end

      should 'accept search' do
        SystemsController.any_instance.expects(:policy_scope).with(Host)
                         .returns(Host.all).at_least_once
        get v1_systems_url, params: { search: 'name=bar' }

        assert_response :success
      end
    end

    context 'destroy' do
      should 'destroy hosts with authorized user' do
        User.current = users(:test)
        users(:test).update(account: accounts(:test))
        hosts(:one).update(account: accounts(:test))
        assert_difference('Host.count', -1) do
          delete "#{v1_systems_url}/#{hosts(:one).id}"
        end
        assert_response :success
      end

      should 'not destroy hosts that do not belong to the user' do
        User.current = users(:test)
        users(:test).update(account: accounts(:test))
        hosts(:one).update(account: nil)
        assert_difference('Host.count', 0) do
          delete "#{v1_systems_url}/#{hosts(:one).id}"
        end
        assert_response :not_found
      end
    end

    context 'show' do
      setup do
        users(:test).update!(account: accounts(:test))
        User.current = users(:test)
        hosts(:one).update!(account: accounts(:test))
      end

      should 'show a host in the related account' do
        get system_path(hosts(:one))
        assert_response :success
        assert_equal hosts(:one).id, JSON.parse(response.body).dig('data', 'id')
      end

      should 'return 404 for hosts in other accounts' do
        get system_path(hosts(:two))
        assert_response :not_found
      end
    end
  end
end
