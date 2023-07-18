# frozen_string_literal: true

require 'test_helper'

class RemediationUpdatesTest < ActiveSupport::TestCase
  setup do
    @issue_id = 'ssg:rhel7|short_profile_ref_id|rule_ref_id'
  end

  test 'handles missing kafka config' do
    RemediationUpdates.stubs(:kafka).returns(nil)
    assert_nil RemediationUpdates.deliver(
      host_id: '0001', issue_ids: [@issue_id]
    )
  end

  test 'delivers messages to the remediation updates topic' do
    kafka = mock('kafka')
    RemediationUpdates.stubs(:kafka).returns(kafka)
    kafka.expects(:produce_async).with(anything)
    RemediationUpdates.deliver(host_id: '0001', issue_ids: [@issue_id])
  end

  test 'handles delivery issues' do
    kafka = mock('kafka')
    RemediationUpdates.stubs(:kafka).returns(kafka)
    kafka.expects(:produce_async).with(anything).raises(WaterDrop::Error.new(1))

    assert_nothing_raised do
      RemediationUpdates.deliver(host_id: '0001', issue_ids: [@issue_id])
    end
  end
end
