# frozen_string_literal: true

require 'test_helper'

class ReportUploadFailedTest < ActiveSupport::TestCase
  setup do
    @acc = FactoryBot.create(:account)
    @host = FactoryBot.create(:host, org_id: @acc.org_id)
  end

  test 'delivers messages to the notifications topic' do
    kafka = mock('kafka')
    ReportUploadFailed.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: 'platform.notifications.ingress')
    ReportUploadFailed.deliver(org_id: @acc.org_id, host: @host, request_id: 'bar', error: 'foo')
  end

  test 'delivers messages to the notifications topic without host' do
    kafka = mock('kafka')
    ReportUploadFailed.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: 'platform.notifications.ingress')
    ReportUploadFailed.deliver(org_id: @acc.org_id, host: nil, request_id: 'bar', error: 'foo')
  end
end
