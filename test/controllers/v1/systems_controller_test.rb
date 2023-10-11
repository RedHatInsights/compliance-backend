# frozen_string_literal: true

require 'test_helper'

module V1
  class SystemsControllerTest < ActionDispatch::IntegrationTest
    setup do
      PolicyHost.any_instance.stubs(:host_supported?).returns(true)
      SystemsController.any_instance.expects(:authenticate_user).yields
      User.current = FactoryBot.create(:user)
      stub_rbac_permissions('inventory:hosts:read')
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

      should 'return hosts from allowed groups' do
        ungrouped_hosts = Host.all.to_a
        @host1 = FactoryBot.create(:host, :with_groups, group_count: 1)
        @host2 = FactoryBot.create(:host, :with_groups, group_count: 1)
        FactoryBot.create(:policy, hosts: Host.all)

        allowed_groups = [@host1.groups.first['id'], nil]

        stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ => [{
                                attribute_filter: {
                                  key: 'group.id',
                                  operation: 'in',
                                  value: allowed_groups
                                }
                              }])

        get v1_systems_url

        hosts = response.parsed_body['data'].map { |h| h['id'] }

        ungrouped_hosts.each { |h| assert_includes hosts, h.id }
        assert_includes hosts, @host1.id
        assert_not_includes hosts, @host2.id
      end

      should 'return ungrouped hosts' do
        ungrouped_hosts = Host.all.to_a
        @host1 = FactoryBot.create(:host, :with_groups, group_count: 1)
        @host2 = FactoryBot.create(:host, :with_groups, group_count: 1)
        FactoryBot.create(:policy, hosts: Host.all)

        allowed_groups = [nil]

        stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_HOSTS_READ => [{
                                attribute_filter: {
                                  key: 'group.id',
                                  operation: 'in',
                                  value: allowed_groups
                                }
                              }])

        get v1_systems_url

        hosts = response.parsed_body['data'].map { |h| h['id'] }

        ungrouped_hosts.each { |h| assert_includes hosts, h.id }
        assert_not_includes hosts, @host1.id
        assert_not_includes hosts, @host2.id
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

      should 'systems can be sorted by group name' do
        FactoryBot.create(:host, groups: [{ name: 'zzz', id: Faker::Internet.uuid }])
        FactoryBot.create(:host, groups: [{ name: 'aaa', id: Faker::Internet.uuid }])

        policy = FactoryBot.create(:policy, hosts: Host.all)

        get v1_systems_url, params: {
          sort_by: %w[groups],
          policy_id: policy.id
        }

        assert_response :success
        result = response.parsed_body

        assert_equal([nil, nil, 'aaa', 'zzz'], result['data'].map do |profile|
          profile['attributes']['groups'].try(:[], 0).try(:[], 'name')
        end)
      end

      should 'sort systems without SSG version as nil' do
        host_1, host_2 = FactoryBot.create_list(:host, 2, org_id: User.current.account.org_id)
        profile_1 = FactoryBot.create(:profile, name: 'profile 1')
        profile_2 = FactoryBot.create(:profile, name: 'profile 2')
        FactoryBot.create(:test_result, profile: profile_1, host: host_1)
        FactoryBot.create(:test_result, profile: profile_2, host: host_2)

        get v1_systems_url, params: {
          sort_by: %w[ssg_version name:desc]

        }

        assert_equal response.parsed_body['data'].count, 2
        assert_response :success
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

      should 'fail if passing an unsupported param' do
        get v1_systems_url, params: { foo: 'bar' }
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

      should 'fail on invalid search columns' do
        SystemsController.any_instance.expects(:policy_scope).with(Host)
                         .returns(Host.all).at_least_once
        get v1_systems_url, params: { search: 'foo=bar' }

        assert_response :unprocessable_entity
        assert_includes response.parsed_body['errors'], "Invalid parameter: Field 'foo' not recognized for searching!"
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

      %w[
        tags=0%2F%00
        tags=0%2F%25
        tags=%06%22%2F%F3%86%A4%8C%25%F1%B1%B5%99
        tags=%C2%A5%06%22%2F%F3%86%A4%8C%25%F1%B1%B5%99l
      ].each do |qstr|
        should "fail with wrongly encoded tag #{qstr}" do
          get [v1_systems_url, qstr].join('?')
          assert_response :unprocessable_entity
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
        host = FactoryBot.create(:host, org_id: 'foo')
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

      should 'include inventory groups' do
        host = FactoryBot.create(:host, groups: [{ id: '1234' }])
        get system_path(host)
        assert_response :success
        assert_equal host.groups, response.parsed_body.dig('data', 'attributes', 'groups')
      end

      should 'search for exact group name' do
        hosts = FactoryBot.create_list(:host, 2, groups: [{ name: 'testgroup' }])
        diff_group_host = FactoryBot.create(:host, groups: [{ name: 'differentGroup' }])

        get v1_systems_url, params: { search: 'group_name = testgroup' }
        response_host_ids = response.parsed_body['data'].map { |h| h['id'] }

        assert_response :success
        assert_not_includes response_host_ids, diff_group_host.id
        hosts.each do |host|
          assert_includes response_host_ids, host.id
        end
      end

      should 'search for group name inclusion' do
        host1 = FactoryBot.create(:host, groups: [{ name: 'testgroup1' }, { name: 'secondGroup' }])
        host2 = FactoryBot.create(:host, groups: [{ name: 'testgroup1' }, { name: 'thirdGroup' }])
        host_ids = [host1.id, host2.id]
        diff_group_host = FactoryBot.create(:host, groups: [{ name: 'secondGroup' }, { name: 'thirdGroup' }])

        get v1_systems_url, params: { search: 'group_name ^ testgroup1' }
        response_host_ids = response.parsed_body['data'].map { |h| h['id'] }

        assert_response :success
        assert_not_includes response_host_ids, diff_group_host.id
        response_host_ids.each do |response_id|
          assert_includes host_ids, response_id
        end
      end

      should 'search for exact group id' do
        hosts = FactoryBot.create_list(:host, 2, groups: [{ id: '1234' }])
        diff_group_host = FactoryBot.create(:host, groups: [{ id: '99999' }])

        get v1_systems_url, params: { search: 'group_id = 1234' }
        response_host_ids = response.parsed_body['data'].map { |h| h['id'] }

        assert_response :success
        assert_not_includes response_host_ids, diff_group_host.id
        hosts.each do |host|
          assert_includes response_host_ids, host.id
        end
      end

      should 'search for group id inclusion' do
        host1 = FactoryBot.create(:host, groups: [{ id: '1234' }, { id: '9999' }])
        host2 = FactoryBot.create(:host, groups: [{ id: '1234' }, { id: '8888' }])
        host_ids = [host1.id, host2.id]
        diff_group_host = FactoryBot.create(:host, groups: [{ id: '9999' }, { id: '8888' }])

        get v1_systems_url, params: { search: 'group_id ^ 1234' }
        response_host_ids = response.parsed_body['data'].map { |h| h['id'] }

        assert_response :success
        assert_not_includes response_host_ids, diff_group_host.id
        response_host_ids.each do |response_id|
          assert_includes host_ids, response_id
        end
      end
    end
  end
end
