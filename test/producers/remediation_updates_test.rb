# frozen_string_literal: true

require 'test_helper'

class RemediationUpdatesTest < ActiveSupport::TestCase
  setup do
    @issue_id = 'ssg:rhel7|short_profile_ref_id|rule_ref_id'
  end

  test 'handles missing kafka config' do
    assert_nil RemediationUpdates.deliver(
      host_id: '0001', issue_ids: [@issue_id]
    )
  end

  test 'delivers messages to the remediation updates topic' do
    kafka = mock('kafka')
    RemediationUpdates.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: RemediationUpdates::TOPIC)
    RemediationUpdates.deliver(host_id: '0001', issue_ids: [@issue_id])
  end

  test 'handles delivery issues' do
    kafka = mock('kafka')
    Kafka.stubs(:new).returns(kafka)
    RemediationUpdates.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: RemediationUpdates::TOPIC)
         .raises(Kafka::DeliveryFailed.new(nil, nil))

    assert_nothing_raised do
      RemediationUpdates.deliver(host_id: '0001', issue_ids: [@issue_id])
    end
  end
end
