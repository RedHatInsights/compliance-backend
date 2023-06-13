# frozen_string_literal: true

require 'test_helper'

class NofiticationTest < ActiveSupport::TestCase
  class MockNotification < Notification
    def self.build_context(**_kwargs)
      {}
    end

    def self.build_events(**_kwargs)
      []
    end
  end

  setup do
    @acc = FactoryBot.create(:account)
  end

  test 'handles missing kafka config' do
    MockNotification.stubs(:kafka).returns(nil)
    assert_nil MockNotification.deliver(account_number: @acc.account_number, org_id: @acc.org_id)
  end

  test 'delivers messages to the notifications topic' do
    kafka = mock('kafka')
    MockNotification.stubs(:kafka).returns(kafka)
    kafka.expects(:produce).with(anything)
    MockNotification.deliver(account_number: @acc.account_number, org_id: @acc.org_id)
  end

  test 'handles delivery issues' do
    kafka = mock('kafka')
    MockNotification.stubs(:kafka).returns(kafka)
    kafka.expects(:produce).with(anything).raises(Rdkafka::RdkafkaError.new(1))

    assert_nothing_raised do
      MockNotification.deliver(account_number: @acc.account_number, org_id: @acc.org_id)
    end
  end
end
