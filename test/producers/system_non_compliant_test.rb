# frozen_string_literal: true

require 'test_helper'

class SystemNonCompliantTest < ActiveSupport::TestCase
  setup do
    @acc = FactoryBot.create(:account)
    @host = FactoryBot.create(:host, account: @acc.account_number)
    @policy = FactoryBot.create(:policy, account: @acc)
  end

  test 'delivers messages to the notifications topic' do
    kafka = mock('kafka')
    SystemNonCompliant.stubs(:kafka).returns(kafka)
    kafka.expects(:deliver_message)
         .with(anything, topic: 'platfom.notifications.ingress')
    SystemNonCompliant.deliver(account_number: @acc.account_number,
                               host: @host, policy: @policy,
                               compliance_score: 90, policy_threshold: 100)
  end
end
