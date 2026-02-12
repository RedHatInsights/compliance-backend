# frozen_string_literal: true

require 'rails_helper'

describe InventoryViews do
  class MockInventoryViews < InventoryViews
    REQUEST_ID = Faker::Internet.uuid
  end

  let!(:system) { FactoryBot.create(:system, policy_id: policy.id) }
  let(:policy) { FactoryBot.create(:v2_policy, os_major_version: 8, supports_minors: [0]) }

  describe 'provided a payload' do
    before do
      karafka.produced_messages.clear
    end

    let(:correct_message) do
      {
        org_id: system.org_id,
        timestamp: DateTime.now.iso8601,
        hosts: [
          {
            id: system.id,
            data: {
              policies: system.policies.map { |p| { id: p.id, title: p.title } },
              last_scan: system.last_check_in
            }
          }
        ]
      }.to_json
    end

    it 'sends a correct message to the correct topic' do
      MockInventoryViews.deliver(request_id: MockInventoryViews::REQUEST_ID, system: system)

      expect(karafka.produced_messages.size).to eq(1)
      expect(karafka.produced_messages.first[:payload]).to eq(correct_message)
      expect(karafka.produced_messages.first[:topic]).to eq('platform.inventory.host-apps')
      expect(karafka.produced_messages.first[:headers].keys).to include('request_id', 'application')
      expect(karafka.produced_messages.first[:headers]['request_id']).to eq(MockInventoryViews::REQUEST_ID)
      expect(karafka.produced_messages.first[:headers]['application']).to eq('compliance')
    end
  end

  describe 'when delivery fails' do
    before do
      allow(MockInventoryViews).to receive(:kafka).and_raise(Rdkafka::RdkafkaError.new(1))
    end

    it 'handles delivery issues' do
      expect(Rails.logger).to receive(:error).with(
        a_string_matching(
          /\AInventoryViews delivery failed:/
        )
      )
      expect do
        MockInventoryViews.deliver(request_id: MockInventoryViews::REQUEST_ID, system: system)
      end.not_to raise_error
    end
  end
end
