# frozen_string_literal: true

require 'rails_helper'

describe PayloadTracker do
  let(:request_id) { '1' }
  let(:status) { 'success' }
  let(:account) { '00001' }
  let(:org_id) { '001' }
  let(:system_id) { Faker::Internet.uuid }
  let(:status_msg) { 'success message' }

  describe 'provided a payload' do
    let(:correct_message) do
      {
        'request_id' => request_id,
        'status' => status,
        'account' => account,
        'org_id' => org_id,
        'system_id' => system_id,
        'status_msg' => status_msg
      }
    end

    it 'sends a correct message to the correct topic' do
      PayloadTracker.deliver(
        request_id: request_id,
        status: status,
        account: account,
        org_id: org_id,
        system_id: system_id,
        status_msg: status_msg
      )

      expect(karafka.produced_messages.size).to eq(1)
      expect(JSON.parse(karafka.produced_messages.first[:payload])).to match(hash_including(correct_message))
      expect(karafka.produced_messages.first[:topic]).to eq('platform.payload-status')
    end
  end

  describe 'when delivery fails' do
    before do
      allow(PayloadTracker).to receive(:kafka).and_raise(Rdkafka::RdkafkaError.new(1))
    end

    it 'handles delivery issues' do
      expect(Rails.logger).to receive(:error).with(
        a_string_matching(
          /\APayload tracker delivery failed:/
        )
      )
      expect do
        PayloadTracker.deliver(
          request_id: request_id,
          status: status,
          account: account,
          org_id: org_id,
          system_id: system_id
        )
      end.to_not raise_error
    end
  end
end
