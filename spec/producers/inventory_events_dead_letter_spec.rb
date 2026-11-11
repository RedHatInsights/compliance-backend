# frozen_string_literal: true

require 'rails_helper'

describe InventoryEventsDeadLetter do
  let(:entry) do
    {
      'type' => Faker::Lorem.word,
      'payload' => { 'id' => Faker::Number.number(digits: 8) },
      'metadata' => { 'request_id' => Faker::Internet.uuid }
    }
  end
  let(:entry_without_metadata) do
    {
      'type' => Faker::Lorem.word,
      'payload' => { 'id' => Faker::Number.number(digits: 8) }
    }
  end
  let(:error) { StandardError.new(Faker::Lorem.sentence) }
  let(:malformed_entry) { { 'metadata' => { 'request_id' => Faker::Internet.uuid } } }

  describe '.TOPIC' do
    it 'uses compliance dlq topic' do
      expect(described_class::TOPIC).to eq(Settings.kafka.topics.compliance_dlq)
    end
  end

  describe '.deliver' do
    it 'projects entry and failure envelope to configured topic' do
      expect(described_class).to receive(:deliver_message).with(
        type: entry['type'],
        payload: entry['payload'],
        metadata: entry['metadata'],
        failure: {
          retry_count: 3,
          error_class: error.class.name,
          error_message: error.message
        }
      )

      described_class.deliver(entry: entry, retry_count: 3, error: error)
    end

    it 'projects empty metadata when entry omits metadata' do
      expect(described_class).to receive(:deliver_message).with(
        type: entry_without_metadata['type'],
        payload: entry_without_metadata['payload'],
        metadata: {},
        failure: {
          retry_count: 3,
          error_class: error.class.name,
          error_message: error.message
        }
      )

      described_class.deliver(entry: entry_without_metadata, retry_count: 3, error: error)
    end

    it 'sanitizes malformed entries missing type and payload' do
      expect(described_class).to receive(:deliver_message).with(
        type: 'inventory_event_processing_failed',
        payload: {},
        metadata: malformed_entry['metadata'],
        failure: {
          retry_count: 3,
          error_class: error.class.name,
          error_message: error.message
        }
      )

      described_class.deliver(entry: malformed_entry, retry_count: 3, error: error)
    end

    it 'sanitizes malformed entries missing type and ignores sensitive payload data' do
      entry_without_type = {
        'payload' => {
          'id' => Faker::Number.number(digits: 8),
          'platform_metadata' => {
            'b64_identity' => Base64.strict_encode64(Faker::Internet.email)
          }
        },
        'metadata' => { 'request_id' => Faker::Internet.uuid }
      }

      expect(described_class).to receive(:deliver_message).with(
        type: 'inventory_event_processing_failed',
        payload: {},
        metadata: entry_without_type['metadata'],
        failure: {
          retry_count: 3,
          error_class: error.class.name,
          error_message: error.message
        }
      )

      described_class.deliver(entry: entry_without_type, retry_count: 3, error: error)
    end

    it 'sanitizes malformed entries missing payload when type is present' do
      entry_without_payload = {
        'type' => Faker::Lorem.word,
        'metadata' => { 'request_id' => Faker::Internet.uuid }
      }

      expect(described_class).to receive(:deliver_message).with(
        type: 'inventory_event_processing_failed',
        payload: {},
        metadata: entry_without_payload['metadata'],
        failure: {
          retry_count: 3,
          error_class: error.class.name,
          error_message: error.message
        }
      )

      described_class.deliver(entry: entry_without_payload, retry_count: 3, error: error)
    end

    it 'does not send a raw key' do
      expect(described_class).not_to receive(:deliver_message).with(hash_including(key: anything))
      allow(described_class).to receive(:deliver_message)

      described_class.deliver(entry: entry, retry_count: 3, error: error)
    end

    it 'does not send a raw value' do
      expect(described_class).not_to receive(:deliver_message).with(hash_including(value: anything))
      allow(described_class).to receive(:deliver_message)

      described_class.deliver(entry: entry, retry_count: 3, error: error)
    end
  end
end
