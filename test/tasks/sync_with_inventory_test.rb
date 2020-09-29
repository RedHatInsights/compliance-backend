# frozen_string_literal: true

require 'test_helper'
require 'rake'

class SyncWithInventoryTest < ActiveSupport::TestCase
  setup do
    HostInventoryAPI.any_instance.stubs(:inventory_host).returns(
      'display_name' => 'foo',
      'os_major_version' => 7,
      'os_minor_version' => 5
    )
  end

  test 'sync_with_inventory' do
    assert_not_equal hosts(:one).name, 'foo'
    assert_nil hosts(:one).os_minor_version
    assert_nil hosts(:one).os_major_version

    Rake::Task['sync_with_inventory'].execute

    assert_equal hosts(:one).reload.name, 'foo'
    assert_equal hosts(:one).os_major_version, 7
    assert_equal hosts(:one).os_minor_version, 5
  end

  test 'sync_with_inventory handles Inventory API errors' do
    HostInventoryAPI.any_instance.stubs(:inventory_host)
                    .raises(Faraday::ServerError.new(500))

    assert_nothing_raised do
      Rake::Task['sync_with_inventory'].execute
    end
  end
end
