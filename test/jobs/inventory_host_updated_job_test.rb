# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class InventoryHostUpdatedJobTest < ActiveSupport::TestCase
  setup do
    @message = {
      'type': 'updated',
      'host': {
        'id': hosts(:one).id,
        'display_name': 'updated_display_name'
      }
    }
    InventoryHostUpdatedJob.clear
  end

  test 'updates a hostname if the passed ID is found' do
    InventoryHostUpdatedJob.perform_async(@message)
    assert_equal 1, InventoryHostUpdatedJob.jobs.size
    InventoryHostUpdatedJob.drain
    assert_equal @message[:host][:display_name], hosts(:one).reload.name
  end

  test 'warns if the message is in an unexpected format' do
    InventoryHostUpdatedJob.perform_async('unexpected': 'format')
    assert_equal 1, InventoryHostUpdatedJob.jobs.size
    Sidekiq.logger.expects(:warn)
    InventoryHostUpdatedJob.drain
  end

  test 'logs if message contains an ID not found ' do
    InventoryHostUpdatedJob.perform_async(
      'host': { 'id': 'notfound', 'display_name': 'abc' }
    )
    assert_equal 1, InventoryHostUpdatedJob.jobs.size
    Sidekiq.logger.expects(:info).at_least_once
    InventoryHostUpdatedJob.drain
  end
end
