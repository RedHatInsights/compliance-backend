# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class DeleteHostTest < ActiveSupport::TestCase
  setup do
    @message = {
      'id': hosts(:one).id,
      'type': 'delete'
    }
    DeleteHost.clear
  end

  test 'deletes a host if the passed ID is found' do
    DeleteHost.perform_async(@message)
    assert_equal 1, DeleteHost.jobs.size
    assert_difference('Host.count', -1) do
      DeleteHost.drain
    end
  end

  test 'logs if message contains an ID not found ' do
    DeleteHost.perform_async(@message.merge('id': 'notfound'))
    assert_equal 1, DeleteHost.jobs.size
    Sidekiq.logger.expects(:info).at_least_once
    assert_difference('Host.count', 0) do
      DeleteHost.drain
    end
  end
end
