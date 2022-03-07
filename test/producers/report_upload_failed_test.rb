# frozen_string_literal: true

require 'test_helper'

class ReportUploadFailedTest < ActiveSupport::TestCase
  setup do
    @acc = FactoryBot.create(:account)
    @host = FactoryBot.create(:host, account: @acc.account_number)
  end

  test 'delivers messages to the notifications topic' do
    kafka = mock('kafka')
    ReportUploadFailed.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: 'platform.notifications.ingress')
    ReportUploadFailed.deliver(account_number: @acc.account_number,
                               host: @host, error: 'foo')
  end
end
