# frozen_string_literal: true

require 'test_helper'

class PayloadTrackerTest < ActiveSupport::TestCase
  test 'handles missing kafka config' do
    PayloadTracker.stubs(:kafka).returns(nil)
    assert_nil PayloadTracker.deliver(request_id: 'foo', status: 'received',
                                      account: '000001', system_id: 'foo',
                                      org_id: '00001')
  end

  test 'delivers messages to the payload tracker topic' do
    kafka = mock('kafka')
    PayloadTracker.stubs(:kafka).returns(kafka)
    kafka.expects(:produce_async).with(anything)
    PayloadTracker.deliver(request_id: 'foo', status: 'received',
                           account: '000001', system_id: 'foo',
                           org_id: '00001')
  end

  test 'handles delivery issues' do
    kafka = mock('kafka')
    PayloadTracker.stubs(:kafka).returns(kafka)
    kafka.expects(:produce_async).with(anything).raises(WaterDrop::Error.new(1))

    assert_nothing_raised do
      PayloadTracker.deliver(request_id: 'foo', status: 'received',
                             account: '000001', system_id: 'foo',
                             org_id: '00001')
    end
  end
end
