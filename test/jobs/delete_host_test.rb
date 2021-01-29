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
    assert_difference('RuleResult.count' => -1, 'TestResult.count' => -1) do
      DeleteHost.drain
    end
  end
end
