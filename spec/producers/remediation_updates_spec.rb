# frozen_string_literal: true

require 'rails_helper'

describe RemediationUpdates do
  let(:system_id) { FactoryBot.create(:system).id }
  let(:issue_ids) { %w[issue_id1 issue_id2] }

  describe 'provided a payload' do
    let(:correct_message) do
      {
        'host_id' => system_id,
        'issues' => issue_ids
      }
    end

    it 'sends a correct message to the correct topic' do
      RemediationUpdates.deliver(host_id: system_id, issue_ids: issue_ids)

      expect(karafka.produced_messages.size).to eq(1)
      expect(JSON.parse(karafka.produced_messages.first[:payload])).to match(hash_including(correct_message))
      expect(karafka.produced_messages.first[:topic]).to eq('platform.remediation-updates.compliance')
    end
  end

  describe 'delivery fails' do
    before do
      allow(RemediationUpdates).to receive(:kafka).and_raise(Rdkafka::RdkafkaError.new(1))
    end

    it 'logs error' do
      expect(Rails.logger).to receive(:error).with(
        a_string_matching(
          /\AFailed to report updates to Remediation service:/
        )
      )

      expect { RemediationUpdates.deliver(host_id: system_id, issue_ids: issue_ids) }.to_not raise_error
    end
  end
end
