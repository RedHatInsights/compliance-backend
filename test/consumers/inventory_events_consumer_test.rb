# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class InventoryEventsConsumerTest < ActiveSupport::TestCase
  setup do
    @message = stub(:message)
    @consumer = InventoryEventsConsumer.new
    DeleteHost.clear
  end

  test 'if message is delete, host is enqueued for deletion' do
    @message.expects(:value).returns(
      '{"type": "delete", '\
      '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '"timestamp": "2019-05-13 21:18:15.797921"}'
    ).at_least_once
    @consumer.process(@message)
    assert_equal 1, DeleteHost.jobs.size
  end

  test 'if message is not delete, no job is enqueued' do
    @message.expects(:value).returns(
      '{"type": "somethingelse", '\
      '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", '\
      '"timestamp": "2019-05-13 21:18:15.797921"}'
    ).at_least_once
    @consumer.process(@message)
    assert_equal 0, DeleteHost.jobs.size
  end
end
