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

    @logger = mock
    Sidekiq.stubs(:logger).returns(@logger)
    @logger.stubs(:info)
    @logger.stubs(:debug)
  end

  test 'deletes a host if the passed ID is found' do
    DeleteHost.perform_async(@message)
    assert_equal 1, DeleteHost.jobs.size
    assert_difference('RuleResult.count' => -1, 'TestResult.count' => -1) do
      DeleteHost.drain
    end
    assert_audited 'Deleteted related records for host'
    assert_audited hosts(:one).id
  end

  test 'delete of a host fails and is audited' do
    DeleteHost.perform_async(@message)
    DeleteHost.any_instance.stubs(:remove_related).raises(StandardError)
    assert_equal 1, DeleteHost.jobs.size
    assert_raises StandardError do
      DeleteHost.drain
    end
    assert_audited 'Failed to delete related records for host'
    assert_audited hosts(:one).id
  end
end
