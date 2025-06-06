# frozen_string_literal: true

require 'rails_helper'

describe Notification do
  class MockNotification < Notification
    EVENT_TYPE = 'mock-event'

    def self.build_events(**)
      []
    end
  end

  let(:org_id) { '001' }
  let(:system) { FactoryBot.create(:system) }

  describe 'provided a payload' do
    let(:correct_message) do
      {
        version: 'v1.1.0',
        bundle: 'rhel',
        application: 'compliance',
        event_type: 'mock-event',
        timestamp: DateTime.now.iso8601,
        org_id: org_id,
        events: [],
        context: {
          display_name: system&.display_name,
          host_url: "https://console.redhat.com/insights/inventory/#{system&.id}",
          inventory_id: system&.id,
          rhel_version: [system&.os_major_version, system&.os_minor_version].join('.'),
          tags: system&.tags
        }.to_json,
        recipients: []
      }.to_json
    end

    it 'sends a correct message to the correct topic' do
      MockNotification.deliver(host: system, org_id: org_id)

      expect(karafka.produced_messages.size).to eq(1)
      expect(karafka.produced_messages.first[:payload]).to eq(correct_message)
      expect(karafka.produced_messages.first[:topic]).to eq('platform.notifications.ingress')
    end
  end

  describe 'when delivery fails' do
    before do
      allow(MockNotification).to receive(:kafka).and_raise(Rdkafka::RdkafkaError.new(1))
    end

    it 'handles delivery issues' do
      expect(Rails.logger).to receive(:error).with(
        a_string_matching(
          /\ANotification delivery failed:/
        )
      )
      expect { MockNotification.deliver(host: system, org_id: org_id) }.to_not raise_error
    end
  end
end
