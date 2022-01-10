# frozen_string_literal: true

require 'test_helper'

class NofiticationTest < ActiveSupport::TestCase
  setup do
    @acc = FactoryBot.create(:account)
    @host = FactoryBot.create(:host, account: @acc.account_number)
    @policy = FactoryBot.create(:policy, account: @acc)
  end

  test 'handles missing kafka config' do
    assert_nil Notification.deliver(event_type: 'report-upload-failed',
                                    account: @acc, host: @host,
                                    policy: @policy)
  end

  test 'delivers messages to the notifications topic' do
    kafka = mock('kafka')
    Notification.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: 'platfom.notifications.ingress')
    Notification.deliver(event_type: 'report-upload-failed',
                         account: @acc, host: @host, policy: @policy)
  end

  test 'handles delivery issues' do
    kafka = mock('kafka')
    Kafka.stubs(:new).returns(kafka)
    Notification.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: 'platfom.notifications.ingress')
         .raises(Kafka::DeliveryFailed.new(nil, nil))

    assert_nothing_raised do
      Notification.deliver(event_type: 'report-upload-failed',
                           account: @acc, host: @host,
                           policy: @policy)
    end
  end
end
