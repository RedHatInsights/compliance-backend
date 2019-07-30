# frozen_string_literal: true

require 'test_helper'
require 'host_inventory_api'

class HostInventoryApiTest < ActiveSupport::TestCase
  setup do
    @account = OpenStruct.new(account_number: 'account_number')
    @host = OpenStruct.new(id: 'hostid', account: 'account_number')
    @new_host = OpenStruct.new(id: 'newhostid', account: 'account_number')
    @url = 'http://localhost'
    @api = HostInventoryAPI.new(@account, @url)
    @connection = mock('faraday_connection')
    HostInventoryAPI.any_instance.stubs(:connection).returns(@connection)
  end

  test 'host_already_in_inventory no host' do
    response = OpenStruct.new(body: { results: [] }.to_json)
    @connection.expects(:get).returns(response).twice
    assert_empty @api.hosts_already_in_inventory([@new_host])[:found]
    assert_equal [@new_host.id],
                 @api.hosts_already_in_inventory([@new_host])[:not_found]
  end

  test 'host_already_in_inventory host exists' do
    response = OpenStruct.new(body: { results: [@host.to_h] }.to_json)
    @connection.expects(:get).returns(response)
    assert_equal [@host.id],
                 @api.hosts_already_in_inventory([@new_host])[:found]
  end

  test 'create_host_in_inventory' do
    response = OpenStruct.new(body: { data: [{ host: @host.to_h }] }.to_json,
                              success?: true)
    @connection.expects(:post).returns(response)
    assert_equal @host.id, @api.create_host_in_inventory['id']
  end

  test 'sync for host already in inventory' do
    @api.expects(:hosts_already_in_inventory).with([@host])
        .returns(found: @host, not_found: [])
    @api.expects(:create_host_in_inventory).never
    assert_equal @host, @api.sync(@host)
  end

  test 'sync for host not already in inventory' do
    @api.expects(:hosts_already_in_inventory).with([@host])
        .returns(found: [], not_found: [@host])
    @api.expects(:create_host_in_inventory).returns(@host)
    assert_equal @host, @api.sync(@host)
  end
end
