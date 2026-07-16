# frozen_string_literal: true

require 'rails_helper'

describe Kafka::SystemRemover do
  let(:service) { described_class.new(message, Karafka.logger) }
  let(:system_id) { Faker::Internet.uuid }
  let(:org_id) { Faker::Number.number(digits: 6).to_s }
  let!(:kafka_system) { FactoryBot.create(:kafka_system, id: system_id, org_id: org_id, updated: 2.days.ago) }

  context 'with simple delete event' do
    let(:message) do
      {
        'id' => system_id,
        'org_id' => org_id
      }
    end

    it 'soft-deletes the KafkaSystem by setting deleted_at to current time' do
      expect(Karafka.logger).to receive(:audit_success).with(/Soft-deleted system/)
      expect { service.remove_system }.to change { KafkaSystem.count }.from(1).to(0)

      system = KafkaSystem.unscoped.find(system_id)
      expect(system.deleted_at).not_to be_nil
    end
  end

  context 'with updated timestamp in delete message' do
    let(:event_time) { 1.day.ago.utc.iso8601 }
    let(:message) do
      {
        'id' => system_id,
        'org_id' => org_id,
        'updated' => event_time
      }
    end

    it 'uses the event timestamp for deleted_at' do
      service.remove_system
      system = KafkaSystem.unscoped.find(system_id)
      expect(system.deleted_at).to eq(Time.zone.parse(event_time))
    end
  end

  context 'with invalid timestamp in delete message' do
    let(:message) do
      {
        'id' => system_id,
        'org_id' => org_id,
        'updated' => 'invalid-timestamp-string'
      }
    end

    it 'logs a warning and falls back to current time' do
      expect(Karafka.logger).to receive(:warn).with(/Failed to parse timestamp 'invalid-timestamp-string'/)
      service.remove_system
      system = KafkaSystem.unscoped.find(system_id)
      expect(system.deleted_at).not_to be_nil
    end
  end

  context 'when existing system has a newer updated timestamp' do
    let(:event_time) { 1.day.ago.utc.iso8601 }
    let(:message) do
      {
        'id' => system_id,
        'org_id' => org_id,
        'updated' => event_time
      }
    end

    before do
      kafka_system.update!(updated: Time.current)
    end

    it 'ignores the delete message and does not soft-delete the system' do
      expect(Karafka.logger).to receive(:info).with(/Ignored stale delete event/)
      expect { service.remove_system }.not_to(change { KafkaSystem.count })
      expect(kafka_system.reload.deleted_at).to be_nil
    end
  end

  context 'when an exception occurs' do
    let(:message) do
      {
        'id' => system_id,
        'org_id' => org_id
      }
    end

    before do
      allow(KafkaSystem).to receive(:where).and_raise(ActiveRecord::ActiveRecordError, 'db error')
    end

    it 'logs audit_fail and re-raises the exception' do
      expect(Karafka.logger).to receive(:audit_fail).with(/Failed to soft-delete system.*db error/)
      expect { service.remove_system }.to raise_error(ActiveRecord::ActiveRecordError, 'db error')
    end
  end
end
