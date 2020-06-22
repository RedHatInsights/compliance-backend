# frozen_string_literal: true

require 'test_helper'
require 'host_inventory_api'

class HostInventoryApiTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:one)
    @inventory_host = { 'id': hosts(:one).id,
                        'fqdn': hosts(:one).name,
                        'account': @account.account_number }
    @host = hosts(:one)
    @url = 'http://localhost'
    @b64_identity = '1234abcd'
    @api = HostInventoryAPI.new(@account, @url, @b64_identity)
    @connection = mock('faraday_connection')
    @system_profile_response = OpenStruct.new(body: {
      results: [{ id: @host.id, system_profile: { os_release: '8.2' } }]
    }.to_json)
    Platform.stubs(:connection).returns(@connection)
  end

  test 'host_already_in_inventory no host' do
    response = OpenStruct.new(body: { results: [] }.to_json)
    @connection.expects(:get).returns(response)
    assert_nil @api.host_already_in_inventory(@host.id)
  end

  test 'host_already_in_inventory host exists' do
    response = OpenStruct.new(body: { results: [@inventory_host] }.to_json)
    @connection.expects(:get).returns(response)
    assert_equal @host.id, @api.host_already_in_inventory(@host.id)['id']
  end

  test 'inventory_host for host already in inventory' do
    @api.expects(:host_already_in_inventory).returns(@host)
    @connection.expects(:get).with(
      "#{@url}#{ENV['PATH_PREFIX']}/inventory/v1/hosts/"\
      "#{@host.id}/system_profile",
      { per_page: 50, page: 1 },
      X_RH_IDENTITY: @b64_identity
    ).returns(@system_profile_response)
    assert_equal @host, @api.inventory_host(@host.id)
    assert_equal 8, @host.os_major_version
    assert_equal 2, @host.os_minor_version
  end

  test 'inventory_host for host not already in inventory' do
    assert_raises(::InventoryHostNotFound) do
      @api.expects(:host_already_in_inventory).returns(nil)
      @api.inventory_host(@host.id)
    end
  end

  test 'find_results matches on ID' do
    assert_equal(
      @api.send(
        :find_results, {
          'results' =>
          [
            { 'account' => @account.account_number, 'id' => @host.id }
          ]
        },
        @host.id
      )['id'],
      @host.id,
      'find_results did not return the expected match by ID'
    )
  end

  test 'system_profile returns a hash with OS info if found' do
    @connection.expects(:get).with(
      "#{@url}#{ENV['PATH_PREFIX']}/inventory/v1/hosts/"\
      "#{@host.id}/system_profile",
      { per_page: 50, page: 1 },
      X_RH_IDENTITY: @b64_identity
    ).returns(@system_profile_response)
    system_profile_results = @api.system_profile([@host.id])
    assert_equal '8', system_profile_results.first[:os_major_version]
    assert_equal '2', system_profile_results.first[:os_minor_version]
    assert_equal @host.id, system_profile_results.first[:id]
  end

  test 'system_profile returns a hash without OS info if not found' do
    wrong_system_profile_response = OpenStruct.new(body: {
      results: [{ id: @host.id, system_profile: { os_release: '' } }]
    }.to_json)
    @connection.expects(:get).with(
      "#{@url}#{ENV['PATH_PREFIX']}/inventory/v1/hosts/"\
      "#{@host.id}/system_profile",
      { per_page: 50, page: 1 },
      X_RH_IDENTITY: @b64_identity
    ).returns(wrong_system_profile_response)
    system_profile_results = @api.system_profile([@host.id])
    assert_equal nil, system_profile_results.first[:os_major_version]
    assert_equal nil, system_profile_results.first[:os_minor_version]
    assert_equal @host.id, system_profile_results.first[:id]
  end
end
