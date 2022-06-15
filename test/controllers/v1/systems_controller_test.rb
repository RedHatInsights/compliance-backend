# frozen_string_literal: true

require 'test_helper'

module V1
  class SystemsControllerTest < ActionDispatch::IntegrationTest
    setup do
      PolicyHost.any_instance.stubs(:host_supported?).returns(true)
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

      should 'systems can be sorted' do
        policy = FactoryBot.create(:policy, hosts: Host.all)

        get v1_systems_url, params: {
          sort_by: %w[os_minor_version name:desc],
          policy_id: policy.id
        }
        assert_response :success

        result = response.parsed_body
        hosts = policy.hosts.pluck(:display_name).sort.reverse

        assert_equal(hosts, result['data'].map do |profile|
          profile['attributes']['name']
        end)
      end

      should 'filter systems based on stale_timestamp' do
        FactoryBot.create(:policy, hosts: Host.all)

        host1, host2 = Host.all

        WHost.find(host2.id).update!(stale_timestamp: 10.days.ago(Time.zone.now))

        get v1_systems_url, params: {
          search: "stale_timestamp > #{Time.zone.now.iso8601}"
        }

        assert_equal response.parsed_body['data'].length, 1
        assert_equal response.parsed_body['data'].first['id'], host1.id
      end

      should 'fail if wrong sort order is set' do
        get v1_systems_url, params: { sort_by: ['name:foo'] }
        assert_response :unprocessable_entity
      end

      should 'fail if sorting by wrong column' do
        get v1_systems_url, params: { sort_by: ['foo'] }
        assert_response :unprocessable_entity
      end

      should 'provide a default search' do
        SystemsController.any_instance.expects(:policy_scope).with(Host)
                         .returns(Host.all).at_least_once
        get v1_systems_url

        assert_response :success
        assert_equal 'has_test_results=true or has_policy=true',
                     response.parsed_body.dig('meta', 'search')
      end

      should 'allow custom search' do
        SystemsController.any_instance.expects(:policy_scope).with(Host)
                         .returns(Host.all).at_least_once
        get v1_systems_url, params: { search: '' }

        assert_response :success
        assert_empty response.parsed_body.dig('meta', 'search')
      end

      should 'allow filtering by tags' do
        host1 = FactoryBot.create(
          :host,
          tags: [
            {
              key: 'env',
              value: 'prod',
              namespace: 'insights-client'
            },
            {
              key: 'env',
              value: 'stage',
              namespace: 'insights-client'
            }
          ]
        )

        FactoryBot.create(
          :host,
          tags: [
            {
              key: 'env',
              value: 'stage',
              namespace: 'insights-client'
            }
          ]
        )

        FactoryBot.create(:policy, hosts: Host.all)

        # The Insights API tags format cannot be constructed using a hash
        get [
          v1_systems_url,
          'tags=insights-client/env=prod&tags=insights-client/env=stage'
        ].join('?')

        assert_response :success
        results = response.parsed_body['data']
        assert_equal results.count, 1
        assert_equal results.first['id'], host1.id
        assert_not_empty response.parsed_body.dig('meta', 'tags')
      end

      %w[
        tags=satellite/lifecycle_environment=Library
        tags=satellite%2Flifecycle_environment=Library
        tags=satellite/lifecycle_environment%3DLibrary
        tags=satellite%2Flifecycle_environment%3DLibrary
      ].each do |qstr|
        should "properly parse #{qstr}" do
          get [v1_systems_url, qstr].join('?')
          tags = response.parsed_body['meta']['tags']

          assert_equal tags, %w[satellite/lifecycle_environment=Library]
        end
      end
    end

    context 'show' do
      should 'show a host in the related account' do
        host = FactoryBot.create(:host)
        get system_path(host)
        assert_response :success
        assert_equal host.id, response.parsed_body.dig('data', 'id')
      end

      should 'return 404 for hosts in other accounts' do
        host = FactoryBot.create(:host, account: 'foo', org_id: 'foo')
        get system_path(host)
        assert_response :not_found
      end

      should 'return timestamps in ISO-6801' do
        host = FactoryBot.create(:host)
        get system_path(host)

        %w[
          culled_timestamp
          stale_timestamp
          stale_warning_timestamp
          updated
        ].each do |ts|
          timestamp = response.parsed_body.dig('data', 'attributes')[ts]
          assert_equal timestamp, Time.parse(timestamp).iso8601
        end
      end
    end
  end
end
