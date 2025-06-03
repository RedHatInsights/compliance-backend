# frozen_string_literal: true

require 'rails_helper'

describe SystemNonCompliant do
  let(:system) { FactoryBot.create(:system) }
  let(:org_id) { '001' }
  # FIXME: Use V2 policy factory
  let(:policy) { FactoryBot.create(:policy, account: system.account) }
  let(:compliance_score) { policy.compliance_threshold - 5.0 }
  let(:event) do
    [{
      'metadata' => {},
      'payload' => {
        'host_id' => system.id,
        'host_name' => system.display_name,
        'policy_id' => policy.initial_profile&.id,
        'policy_name' => policy.name,
        'policy_threshold' => policy.compliance_threshold.round(1),
        'compliance_score' => compliance_score.round(1)
      }.to_json
    }]
  end

  it 'provides event details to notification' do
    SystemNonCompliant.deliver(
      host: system,
      org_id: org_id,
      policy: policy,
      policy_threshold: policy.compliance_threshold,
      compliance_score: compliance_score
    )

    sent_payload = JSON.parse(karafka.produced_messages.first[:payload])

    expect(karafka.produced_messages.size).to eq(1)
    expect(sent_payload.dig('events')).to match(array_including(event))
    expect(sent_payload['event_type']).to eq('compliance-below-threshold')
    expect(karafka.produced_messages.first[:topic]).to eq('platform.notifications.ingress')
  end
end
