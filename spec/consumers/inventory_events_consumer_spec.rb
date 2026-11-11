# frozen_string_literal: true

require 'rails_helper'

describe InventoryEventsConsumer do
  subject(:consumer) { karafka.consumer_for(Settings.kafka.topics.inventory_events) }

  let(:metadata) do
    {
      'topic' => 'platform.inventory.hosts',
      'partition' => partition,
      'offset' => offset,
      'timestamp' => '2026-10-14T10:00:00Z'
    }
  end
  let(:partition) { 2 }
  let(:offset) { 41 }
  let(:message) { kafka_message({ 'type' => 'somethingelse' }) }
  let(:importable_message) { kafka_message(importable_event) }
  let(:importable_event) do
    {
      'type' => 'created',
      'host' => { 'id' => SecureRandom.uuid, 'insights_id' => SecureRandom.uuid }
    }
  end

  def kafka_message(payload, message_metadata = metadata)
    instance_double(
      Karafka::Messages::Message,
      raw_payload: payload.to_json,
      topic: message_metadata['topic'],
      partition: message_metadata['partition'],
      offset: message_metadata['offset'],
      timestamp: message_metadata['timestamp']
    )
  end

  before do
    allow(consumer).to receive(:messages).and_return([message])
    allow(consumer).to receive(:log_metadata)
    allow(consumer).to receive(:mark_as_consumed)
  end

  it 'enqueues one ordered batch with projected payloads and per-message metadata' do
    created = {
      'type' => 'created',
      'id' => SecureRandom.uuid,
      'host' => {
        'id' => SecureRandom.uuid,
        'insights_id' => SecureRandom.uuid,
        'display_name' => Faker::Internet.domain_name,
        'unrelated' => Faker::Lorem.word
      }
    }
    deleted = {
      'type' => 'delete',
      'id' => SecureRandom.uuid,
      'org_id' => Faker::Number.number(digits: 6).to_s,
      'updated' => Time.current.iso8601,
      'unrelated' => Faker::Lorem.word
    }
    unknown = {
      'type' => 'somethingelse',
      'platform_metadata' => { 'service' => 'inventory' },
      'unrelated' => Faker::Lorem.word
    }
    ineligible = created.merge('type' => 'updated', 'host' => created['host'].merge('insights_id' => nil))
    messages = [
      kafka_message(created, metadata.merge('partition' => 1, 'offset' => 10)),
      kafka_message(deleted, metadata.merge('partition' => 2, 'offset' => 11)),
      kafka_message(unknown, metadata.merge('partition' => 3, 'offset' => 12)),
      kafka_message(ineligible, metadata.merge('partition' => 4, 'offset' => 13))
    ]
    allow(consumer).to receive(:messages).and_return(messages)

    expected_entries = [
      {
        'type' => 'created',
        'payload' => created.slice('type', 'id').merge(
          'host' => created['host'].slice('id', 'insights_id', 'display_name')
        ),
        'metadata' => metadata.merge('partition' => 1, 'offset' => 10)
      },
      {
        'type' => 'delete',
        'payload' => deleted.slice('id', 'org_id', 'updated', 'timestamp'),
        'metadata' => metadata.merge('partition' => 2, 'offset' => 11)
      }
    ]

    expect(InventoryEventsBatchJob).to receive(:perform_later).with(expected_entries).and_return(true).ordered
    expect(consumer).to receive(:mark_as_consumed).with(messages[0]).ordered
    expect(consumer).to receive(:mark_as_consumed).with(messages[1]).ordered
    expect(consumer).to receive(:mark_as_consumed).with(messages[2]).ordered
    expect(consumer).to receive(:mark_as_consumed).with(messages[3]).ordered

    consumer.consume
  end

  it 'logs and acknowledges an unknown event without batching or parsing reports' do
    expect(consumer).to receive(:messages).once.and_return([message])
    expect(consumer).to receive(:logger).and_return(Rails.logger)
    expect(Rails.logger).to receive(:debug).with("Skipped message of type 'somethingelse'")
    expect(InventoryEventsBatchJob).not_to receive(:perform_later)
    expect(Kafka::ReportParser).not_to receive(:new)
    expect(consumer).to receive(:mark_as_consumed).with(message)

    consumer.consume
  end

  describe 'ineligible import hosts' do
    let(:event) do
      {
        'type' => 'created',
        'host' => { 'id' => SecureRandom.uuid }.merge(host_attributes)
      }
    end
    let(:host_attributes) { {} }
    let(:ineligible_message) { kafka_message(event) }

    shared_examples 'an ineligible host' do
      it 'does not include the host in a batch and acknowledges the message' do
        expect(InventoryEventsBatchJob).not_to receive(:perform_later)
        expect(consumer).to receive(:mark_as_consumed).with(ineligible_message)

        allow(consumer).to receive(:messages).and_return([ineligible_message])
        consumer.consume
      end
    end

    context 'without an Insights ID' do
      include_examples 'an ineligible host'
    end

    context 'with the NON_INSIGHTS_ID sentinel' do
      let(:host_attributes) { { 'insights_id' => described_class::NON_INSIGHTS_ID } }

      include_examples 'an ineligible host'
    end

    context 'when the host is edge' do
      let(:host_attributes) do
        { 'insights_id' => SecureRandom.uuid, 'system_profile' => { 'host_type' => 'edge' } }
      end

      include_examples 'an ineligible host'
    end

    context 'when the operating system is CentOS' do
      let(:host_attributes) do
        {
          'insights_id' => SecureRandom.uuid,
          'system_profile' => { 'operating_system' => { 'name' => 'CentOS Linux' } }
        }
      end

      include_examples 'an ineligible host'
    end

    context 'when the host is booted from a bootc image' do
      let(:host_attributes) do
        {
          'insights_id' => SecureRandom.uuid,
          'system_profile' => { 'bootc_status' => { 'booted' => { 'image_digest' => "sha256:#{SecureRandom.hex}" } } }
        }
      end

      include_examples 'an ineligible host'
    end
  end

  it 'parses each delivered Kafka payload exactly once' do
    first_event = { 'type' => 'created', 'host' => { 'id' => SecureRandom.uuid, 'insights_id' => SecureRandom.uuid } }
    second_event = { 'type' => 'updated', 'host' => { 'id' => SecureRandom.uuid } }
    messages = [kafka_message(first_event), kafka_message(second_event)]
    allow(consumer).to receive(:messages).and_return(messages)
    messages.each do |delivered_message|
      expect(JSON).to receive(:parse).with(delivered_message.raw_payload).once.and_call_original
    end
    expect(InventoryEventsBatchJob).to receive(:perform_later).with(
      [{ 'type' => 'created', 'payload' => first_event, 'metadata' => metadata }]
    ).and_return(true)

    consumer.consume
  end

  it 'preserves rich import and delete projections' do
    event = {
      'type' => 'updated', 'id' => SecureRandom.uuid,
      'host' => {
        'id' => SecureRandom.uuid, 'insights_id' => SecureRandom.uuid, 'account' => '123',
        'display_name' => 'host.example.com', 'system_profile' => {
          'owner_id' => SecureRandom.uuid,
          'operating_system' => { 'major' => '9', 'minor' => '4', 'name' => 'RHEL', 'extra' => true },
          'image_builder' => { 'compliance_policy_id' => SecureRandom.uuid, 'extra' => true }
        }, 'irrelevant' => 'omit-me'
      },
      'platform_metadata' => {
        'service' => 'compliance', 'request_id' => SecureRandom.uuid,
        'metadata' => { 'full' => { 'nested' => 'value' } }, 'extra' => true
      }, 'irrelevant' => 'omit-me'
    }
    allow(consumer).to receive(:messages).and_return([kafka_message(event)])
    expected_payload = {
      'type' => 'updated', 'id' => event['id'],
      'host' => {
        'id' => event['host']['id'], 'insights_id' => event['host']['insights_id'],
        'account' => '123', 'display_name' => 'host.example.com',
        'system_profile' => {
          'owner_id' => event['host']['system_profile']['owner_id'],
          'operating_system' => { 'major' => '9', 'minor' => '4' },
          'image_builder' => {
            'compliance_policy_id' => event['host']['system_profile']['image_builder']['compliance_policy_id']
          }
        }
      },
      'platform_metadata' => {
        'service' => 'compliance', 'request_id' => event['platform_metadata']['request_id'],
        'metadata' => { 'full' => { 'nested' => 'value' } }
      }
    }
    expect(InventoryEventsBatchJob).to receive(:perform_later).with(
      [{ 'type' => 'updated', 'payload' => expected_payload, 'metadata' => metadata }]
    ).and_return(true)

    consumer.consume
  end

  describe 'with a malformed message in the delivery' do
    let(:valid_a) { kafka_message(importable_event, metadata.merge('offset' => 1)) }
    let(:valid_b) { kafka_message(importable_event.merge('type' => 'updated'), metadata.merge('offset' => 2)) }
    let(:malformed) do
      instance_double(Karafka::Messages::Message, raw_payload: Faker::Lorem.word, topic: metadata['topic'],
                                                  partition: partition, offset: 3, timestamp: metadata['timestamp'])
    end
    let(:valid_d) { kafka_message(importable_event, metadata.merge('offset' => 4)) }

    it 'batches and acknowledges only the messages before the malformed one, then raises' do
      allow(consumer).to receive(:messages).and_return([valid_a, valid_b, malformed, valid_d])
      expect(InventoryEventsBatchJob).to receive(:perform_later) do |entries|
        expect(entries.map { |entry| entry['metadata']['offset'] }).to eq([1, 2])
        true
      end.once.ordered
      acknowledged = []
      allow(consumer).to receive(:mark_as_consumed) { |delivered_message| acknowledged << delivered_message }
      allow(valid_d).to receive(:raw_payload)

      expect { consumer.consume }.to raise_error(JSON::ParserError)
      expect(acknowledged).to eq([valid_a, valid_b])
      expect(valid_d).not_to have_received(:raw_payload)
    end

    it 'raises without batching or acknowledging when the malformed message is first' do
      allow(consumer).to receive(:messages).and_return([malformed, valid_a])
      expect(InventoryEventsBatchJob).not_to receive(:perform_later)

      expect { consumer.consume }.to raise_error(JSON::ParserError)
      expect(consumer).not_to have_received(:mark_as_consumed)
    end

    it 'acknowledges nothing and raises the enqueue error when batching the valid prefix fails' do
      allow(consumer).to receive(:messages).and_return([valid_a, malformed])
      allow(InventoryEventsBatchJob).to receive(:perform_later).and_raise(StandardError, 'enqueue failed')

      expect { consumer.consume }.to raise_error(StandardError, 'enqueue failed')
      expect(consumer).not_to have_received(:mark_as_consumed)
    end
  end

  it 'batches all actionable entries once and acknowledges every delivered message' do
    first = kafka_message(importable_event, metadata.merge('offset' => 1))
    skipped = kafka_message({ 'type' => 'somethingelse' }, metadata.merge('offset' => 2))
    last = kafka_message(importable_event.merge('type' => 'updated'), metadata.merge('offset' => 3))
    delivered = [first, skipped, last]
    allow(consumer).to receive(:messages).and_return(delivered)
    expect(InventoryEventsBatchJob).to receive(:perform_later) do |entries|
      expect(entries.map { |entry| entry['metadata']['offset'] }).to eq([1, 3])
      true
    end.once.ordered
    delivered.each do |delivered_message|
      expect(consumer).to receive(:mark_as_consumed).with(delivered_message).ordered
    end

    consumer.consume
  end

  it 'propagates enqueue failures without acknowledging messages' do
    allow(consumer).to receive(:messages).and_return([importable_message])
    allow(InventoryEventsBatchJob).to receive(:perform_later).and_raise(StandardError, 'enqueue failed')

    expect { consumer.consume }.to raise_error(StandardError, 'enqueue failed')
    expect(consumer).not_to have_received(:mark_as_consumed)
  end

  it 'raises when enqueue returns false without acknowledging messages' do
    allow(consumer).to receive(:messages).and_return([importable_message])
    allow(InventoryEventsBatchJob).to receive(:perform_later).and_return(false)

    expect { consumer.consume }.to raise_error(ActiveJob::EnqueueError, /Failed to enqueue/)
    expect(consumer).not_to have_received(:mark_as_consumed)
  end

  it 'acknowledges a delivery without processable entries' do
    allow(consumer).to receive(:messages).and_return([message])

    expect(InventoryEventsBatchJob).not_to receive(:perform_later)
    expect(consumer).to receive(:mark_as_consumed).with(message)

    consumer.consume
  end

  it 'does not enqueue or acknowledge an empty delivery' do
    allow(consumer).to receive(:messages).and_return([])

    expect(InventoryEventsBatchJob).not_to receive(:perform_later)
    consumer.consume

    expect(consumer).not_to have_received(:mark_as_consumed)
  end
end
