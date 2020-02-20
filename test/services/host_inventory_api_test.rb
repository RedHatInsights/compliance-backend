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
    @api = HostInventoryAPI.new(@host.id, @host.name, @account,
                                @url, @b64_identity)
    @connection = mock('faraday_connection')
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

  test 'create_host_in_inventory' do
    response = OpenStruct.new(
      body: { data: [{ host: @inventory_host }] }.to_json,
      success?: true
    )

    @connection.expects(:post).returns(response)
    assert_equal @host.id, @api.create_host_in_inventory['id']
  end

  test 'inventory_host for host already in inventory' do
    @api.expects(:host_already_in_inventory).returns(@host)
    @api.expects(:create_host_in_inventory).never
    assert_equal @host, @api.inventory_host
  end

  test 'inventory_host for host not already in inventory' do
    @api.expects(:host_already_in_inventory).twice
    @api.expects(:create_host_in_inventory).returns(@host)
    assert_equal @host, @api.inventory_host
  end

  test 'find_results matches on ID' do
    assert_equal(
      @api.send(
        :find_results, 'results' => [
          { 'account' => @account.account_number, 'id' => @host.id }
        ]
      )['id'],
      @host.id,
      'find_results did not return the expected match by ID'
    )
  end

  test 'find_results matches on hostname' do
    assert_equal(
      @api.send(
        :find_results, 'results' => [
          { 'account' => @account.account_number, 'fqdn' => @host.name }
        ]
      )['fqdn'],
      @host.name,
      'find_results did not return the expected match by hostname'
    )
  end
end
