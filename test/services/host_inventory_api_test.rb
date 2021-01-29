# frozen_string_literal: true

require 'test_helper'
require 'host_inventory_api'

class HostInventoryApiTest < ActiveSupport::TestCase
  setup do
    @inventory_host = { 'id' => hosts(:one).id,
                        'display_name' => hosts(:one).name,
                        'account' => hosts(:one).account_number }
    @account = hosts(:one).account_object
    @b64_identity = '1234abcd'
    @api = HostInventoryApi.new(b64_identity: @b64_identity)
    @connection = mock('faraday_connection')
    Platform.stubs(:connection).returns(@connection)
  end

  test 'works with nil b64_identity' do
    api = HostInventoryApi.new(account: @account, b64_identity: nil)
    assert_equal @account.b64_identity,
                 api.instance_variable_get(:@b64_identity)
  end

  test 'hosts queries inventory hosts endpoint' do
    response = OpenStruct.new(body: { results: [@inventory_host] }.to_json)
    @connection.expects(:get).returns(response)

    assert_includes @api.hosts.dig('results').map { |h| h['id'] },
                    hosts(:one).id
  end
end
