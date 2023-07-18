# frozen_string_literal: true

require 'test_helper'

class SystemNonCompliantTest < ActiveSupport::TestCase
  setup do
    @acc = FactoryBot.create(:account)
    @host = FactoryBot.create(:host, org_id: @acc.org_id)
    @policy = FactoryBot.create(:policy, account: @acc)
  end

  test 'delivers messages to the notifications topic' do
    kafka = mock('kafka')
    SystemNonCompliant.stubs(:kafka).returns(kafka)
    kafka.expects(:produce_async).with(anything)
    SystemNonCompliant.deliver(account_number: @acc.account_number, org_id: @acc.org_id,
                               host: @host, policy: @policy,
                               compliance_score: 90, policy_threshold: 100)
  end

  test 'delivers messages to the notifications topic without host' do
    kafka = mock('kafka')
    SystemNonCompliant.stubs(:kafka).returns(kafka)
    kafka.expects(:produce_async).with(anything)
    SystemNonCompliant.deliver(account_number: @acc.account_number,
                               host: nil, policy: @policy, org_id: @acc.org_id,
                               compliance_score: 90, policy_threshold: 100)
  end
end
