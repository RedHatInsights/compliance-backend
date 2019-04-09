# frozen_string_literal: true

require 'test_helper'
require 'host_inventory_api'

class HostInventoryApiTest < ActiveSupport::TestCase
  setup do
    @account = OpenStruct.new(account_number: 'account_number')
    @host = OpenStruct.new(id: 'hostid', account: 'account_number')
    @new_host = OpenStruct.new(account: 'account_number')
    @url = 'http://localhost'
    @b64_identity = '1234abcd'
    @api = HostInventoryAPI.new(@new_host, @account, @url, @b64_identity)
    @connection = mock('faraday_connection')
    HostInventoryAPI.any_instance.stubs(:connection).returns(@connection)
  end

  test 'host_already_in_inventory no host' do
    response = OpenStruct.new(body: { results: [] }.to_json)
    @connection.expects(:get).returns(response)
    assert_nil @api.host_already_in_inventory
  end

  test 'host_already_in_inventory host exists' do
    response = OpenStruct.new(body: { results: [@host.to_h] }.to_json)
    @connection.expects(:get).returns(response)
    assert_equal @host.id, @api.host_already_in_inventory['id']
  end

  test 'create_host_in_inventory' do
    response = OpenStruct.new(body: { data: [{ host: @host.to_h }] }.to_json,
                              success?: true)
    @connection.expects(:post).returns(response)
    assert_equal @host.id, @api.create_host_in_inventory['id']
  end

  test 'sync for host already in inventory' do
    @api.expects(:host_already_in_inventory).returns(@host)
    @api.expects(:create_host_in_inventory).never
    assert_equal @host, @api.sync
  end

  test 'sync for host not already in inventory' do
    @api.expects(:host_already_in_inventory)
    @api.expects(:create_host_in_inventory).returns(@host)
    assert_equal @host, @api.sync
  end
end
