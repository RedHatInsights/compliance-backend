# frozen_string_literal: true

require 'test_helper'

class PayloadTrackerTest < ActiveSupport::TestCase
  test 'handles missing kafka config' do
    assert_nil PayloadTracker.deliver(request_id: 'foo', status: 'received',
                                      account: '000001', system_id: 'foo')
  end

  test 'delivers messages to the payload tracker topic' do
    kafka = mock('kafka')
    PayloadTracker.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
    PayloadTracker.deliver(request_id: 'foo', status: 'received',
                           account: '000001', system_id: 'foo')
  end

  test 'handles delivery issues' do
    kafka = mock('kafka')
    Kafka.stubs(:new).returns(kafka)
    PayloadTracker.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message).raises(Kafka::DeliveryFailed.new(nil, nil))

    assert_nothing_raised do
      PayloadTracker.deliver(request_id: 'foo', status: 'received',
                             account: '000001', system_id: 'foo')
    end
  end
end
