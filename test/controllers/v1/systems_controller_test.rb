# frozen_string_literal: true

require 'test_helper'

module V1
  class SystemsControllerTest < ActionDispatch::IntegrationTest
    setup do
      SystemsController.any_instance.expects(:authenticate_user).yields
      User.current = FactoryBot.create(:user)
    end

    context 'index' do
      setup do
        FactoryBot.create_list(:host, 2)
      end

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

      should 'provide a default search' do
        SystemsController.any_instance.expects(:policy_scope).with(Host)
                         .returns(Host.all).at_least_once
        get v1_systems_url

        assert_response :success
        assert_equal 'has_test_results=true or has_policy=true',
                     JSON.parse(response.body).dig('meta', 'search')
      end

      should 'allow custom search' do
        SystemsController.any_instance.expects(:policy_scope).with(Host)
                         .returns(Host.all).at_least_once
        get v1_systems_url, params: { search: '' }

        assert_response :success
        assert_empty JSON.parse(response.body).dig('meta', 'search')
      end
    end

    context 'show' do
      should 'show a host in the related account' do
        host = FactoryBot.create(:host)
        get system_path(host)
        assert_response :success
        assert_equal host.id, JSON.parse(response.body).dig('data', 'id')
      end

      should 'return 404 for hosts in other accounts' do
        host = FactoryBot.create(:host, account: 'foo')
        get system_path(host)
        assert_response :not_found
      end
    end
  end
end
