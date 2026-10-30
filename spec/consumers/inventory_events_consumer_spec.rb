# frozen_string_literal: true

require 'rails_helper'

describe InventoryEventsConsumer do
  subject(:consumer) { karafka.consumer_for(Settings.kafka.topics.inventory_events) }

  let(:topic) { 'platform.inventory.hosts' }
  let(:partition_one) { 1 }
  let(:partition_two) { 2 }
  let(:payloads) do
    [
      { 'type' => 'created', 'id' => 'created-id', 'host' => { 'id' => 'host-1', 'unrelated' => 'drop' } },
      { 'type' => 'delete', 'id' => 'delete-id', 'org_id' => 'org-1', 'updated' => 'updated-at' },
      { 'type' => 'unknown', 'platform_metadata' => { 'service' => 'inventory' }, 'full' => true }
    ]
  end

  let(:messages) do
    [
      message(payloads[0], partition_one, 10),
      message(payloads[1], partition_two, 20),
      message(payloads[2], partition_one, 11)
    ]
  end

  def message(payload, partition, offset)
    instance_double(
      Karafka::Messages::Message,
      raw_payload: payload.to_json,
      topic: topic,
      partition: partition,
      offset: offset,
      timestamp: "2026-10-14T10:#{offset}:00Z"
    )
  end

  before do
    allow(consumer).to receive(:messages).and_return(messages)
    allow(consumer).to receive(:log_metadata)
    allow(consumer).to receive(:mark_as_consumed)
  end

  it 'enqueues one ordered batch per topic-partition and acknowledges after enqueue' do
    import = { 'type' => 'created', 'id' => 'created-id', 'host' => { 'id' => 'host-1' } }
    delete = { 'type' => 'delete', 'id' => 'delete-id', 'org_id' => 'org-1', 'updated' => 'updated-at' }
    unknown = payloads[2]

    expect(InventoryEventsBatchJob).to receive(:perform_later).with(
      [
        { 'type' => 'created', 'payload' => import,
          'metadata' => { 'topic' => topic, 'partition' => partition_one, 'offset' => 10,
                          'timestamp' => '2026-10-14T10:10:00Z' } },
        { 'type' => 'unknown', 'payload' => unknown,
          'metadata' => { 'topic' => topic, 'partition' => partition_one, 'offset' => 11,
                          'timestamp' => '2026-10-14T10:11:00Z' } }
      ],
      { 'topic' => topic, 'partition' => partition_one }
    ).ordered
    expect(consumer).to receive(:mark_as_consumed).with(messages[0]).ordered
    expect(consumer).to receive(:mark_as_consumed).with(messages[2]).ordered
    expect(InventoryEventsBatchJob).to receive(:perform_later).with(
      [{ 'type' => 'delete', 'payload' => delete,
         'metadata' => { 'topic' => topic, 'partition' => partition_two, 'offset' => 20,
                         'timestamp' => '2026-10-14T10:20:00Z' } }],
      { 'topic' => topic, 'partition' => partition_two }
    ).ordered
    expect(consumer).to receive(:mark_as_consumed).with(messages[1]).ordered

    consumer.consume
  end

  it 'projects the complete retained import fields from a rich created payload' do
    payload = {
      'type' => 'created',
      'id' => 'system-id',
      'unrelated' => 'drop-root',
      'host' => {
        'id' => 'host-id',
        'insights_id' => 'insights-id',
        'account' => 'account-id',
        'org_id' => 'org-id',
        'display_name' => 'host-name',
        'groups' => ['group-one'],
        'tags' => [{ 'namespace' => 'insights', 'key' => 'env', 'value' => 'test' }],
        'stale_timestamp' => '2026-10-14T09:00:00Z',
        'created' => '2026-10-13T09:00:00Z',
        'updated' => '2026-10-14T09:00:00Z',
        'unrelated' => 'drop-host',
        'system_profile' => {
          'owner_id' => 'owner-id',
          'host_type' => 'edge',
          'unrelated' => 'drop-profile',
          'operating_system' => {
            'major' => '9', 'minor' => '4', 'name' => 'Red Hat Enterprise Linux', 'unrelated' => 'drop-os'
          },
          'bootc_status' => {
            'booted' => { 'image_digest' => 'sha256:abc123', 'unrelated' => 'drop-booted' },
            'unrelated' => 'drop-bootc'
          },
          'image_builder' => { 'compliance_policy_id' => 'policy-id', 'unrelated' => 'drop-builder' }
        }
      },
      'platform_metadata' => {
        'service' => 'compliance',
        'request_id' => 'request-id',
        'org_id' => 'org-id',
        'b64_identity' => 'identity',
        'url' => 'https://example.test/report',
        'metadata' => { 'full' => { 'nested' => 'value' } },
        'unrelated' => 'drop-platform'
      }
    }
    import_entry = {
      'type' => 'created',
      'payload' => {
        'type' => 'created',
        'id' => 'system-id',
        'host' => {
          'id' => 'host-id',
          'insights_id' => 'insights-id',
          'account' => 'account-id',
          'org_id' => 'org-id',
          'display_name' => 'host-name',
          'groups' => ['group-one'],
          'tags' => [{ 'namespace' => 'insights', 'key' => 'env', 'value' => 'test' }],
          'stale_timestamp' => '2026-10-14T09:00:00Z',
          'created' => '2026-10-13T09:00:00Z',
          'updated' => '2026-10-14T09:00:00Z',
          'system_profile' => {
            'owner_id' => 'owner-id',
            'host_type' => 'edge',
            'operating_system' => { 'major' => '9', 'minor' => '4', 'name' => 'Red Hat Enterprise Linux' },
            'bootc_status' => { 'booted' => { 'image_digest' => 'sha256:abc123' } },
            'image_builder' => { 'compliance_policy_id' => 'policy-id' }
          }
        },
        'platform_metadata' => {
          'service' => 'compliance',
          'request_id' => 'request-id',
          'org_id' => 'org-id',
          'b64_identity' => 'identity',
          'url' => 'https://example.test/report',
          'metadata' => { 'full' => { 'nested' => 'value' } }
        }
      },
      'metadata' => {
        'topic' => topic, 'partition' => partition_one, 'offset' => 10,
        'timestamp' => '2026-10-14T10:10:00Z'
      }
    }
    allow(consumer).to receive(:messages).and_return([message(payload, partition_one, 10)])

    expect(InventoryEventsBatchJob).to receive(:perform_later).with(
      [import_entry], { 'topic' => topic, 'partition' => partition_one }
    )

    consumer.consume
  end

  it 'projects only the retained fields from a rich delete payload' do
    payload = {
      'type' => 'delete', 'id' => 'delete-id', 'org_id' => 'org-id', 'updated' => 'updated-at',
      'timestamp' => 'timestamp-at', 'unrelated' => 'drop-root',
      'host' => { 'id' => 'host-id', 'unrelated' => 'drop-host' },
      'platform_metadata' => { 'service' => 'inventory', 'unrelated' => 'drop-platform' }
    }
    allow(consumer).to receive(:messages).and_return([message(payload, partition_two, 20)])

    expect(InventoryEventsBatchJob).to receive(:perform_later).with(
      [{ 'type' => 'delete',
         'payload' => { 'id' => 'delete-id', 'org_id' => 'org-id', 'updated' => 'updated-at',
                        'timestamp' => 'timestamp-at' },
         'metadata' => { 'topic' => topic, 'partition' => partition_two, 'offset' => 20,
                         'timestamp' => '2026-10-14T10:20:00Z' } }],
      { 'topic' => topic, 'partition' => partition_two }
    )

    consumer.consume
  end

  it 'retains the full compliance payload without parsing synchronously' do
    compliance = payloads[2].merge('platform_metadata' => { 'service' => 'compliance' })
    compliance_message = message(compliance, partition_one, 10)
    allow(consumer).to receive(:messages).and_return([compliance_message])

    expect(Kafka::ReportParser).not_to receive(:new)
    expect(InventoryEventsBatchJob).to receive(:perform_later).with(
      [{ 'type' => 'unknown', 'payload' => compliance,
         'metadata' => { 'topic' => topic, 'partition' => partition_one, 'offset' => 10,
                         'timestamp' => '2026-10-14T10:10:00Z' } }],
      { 'topic' => topic, 'partition' => partition_one }
    )

    consumer.consume
  end

  it 'does not acknowledge a group when enqueue fails' do
    allow(InventoryEventsBatchJob).to receive(:perform_later).and_raise(StandardError, 'enqueue failed')

    expect { consumer.consume }.to raise_error(StandardError, 'enqueue failed')
    expect(consumer).not_to have_received(:mark_as_consumed)
  end
end
