# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsBatchJob do
  let(:kafka_metadata) do
    { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41, 'timestamp' => '2026-10-14T10:00:00Z' }
  end
  def entry(system_id:, offset:, type: 'created')
    payload = type == 'delete' ? { 'id' => system_id } : { 'host' => { 'id' => system_id } }
    { 'type' => type, 'payload' => payload, 'metadata' => kafka_metadata.merge('offset' => offset) }
  end

  it 'dispatches created, delete, and compliance report entries in order with payload metadata' do
    import_entry = entry(system_id: Faker::Internet.uuid, offset: 42)
    delete_entry = entry(system_id: Faker::Internet.uuid, offset: 43, type: 'delete')
    report_entry = entry(system_id: Faker::Internet.uuid, offset: 44, type: 'report')
    report_entry['payload']['platform_metadata'] = { 'service' => 'compliance' }
    import_runner = instance_double(SystemImportJob)
    delete_runner = instance_double(SystemDeleteJob)
    report_parser = instance_double(Kafka::ReportParser)

    expect(SystemImportJob).to receive(:new).with(import_entry['payload'], import_entry['metadata'])
                                            .ordered.and_return(import_runner)
    expect(import_runner).to receive(:perform).with(import_entry['payload'], import_entry['metadata']).ordered
    expect(SystemDeleteJob).to receive(:new).with(delete_entry['payload'], delete_entry['metadata'])
                                            .ordered.and_return(delete_runner)
    expect(delete_runner).to receive(:perform).with(delete_entry['payload'], delete_entry['metadata']).ordered
    expect(Kafka::ReportParser).to receive(:new).with(report_entry['payload'], Rails.logger)
                                                .ordered.and_return(report_parser)
    expect(report_parser).to receive(:parse_reports).ordered

    described_class.perform_now([import_entry, delete_entry, report_entry], kafka_metadata)
  end

  it 'logs and skips unknown non-compliance messages' do
    unknown_entry = {
      'type' => 'unknown',
      'payload' => { 'platform_metadata' => { 'service' => 'inventory' } },
      'metadata' => kafka_metadata.merge('offset' => 42)
    }
    expect(Rails.logger).to receive(:debug) do |&message|
      expect(message.call).to eq("Skipped message of type 'unknown'")
    end

    described_class.perform_now([unknown_entry], kafka_metadata)
  end

  it 'routes deletes by entry type and retains their metadata' do
    delete_entry = entry(system_id: Faker::Internet.uuid, offset: 42, type: 'delete')
    delete_entry['payload']['type'] = 'created'
    delete_runner = instance_double(SystemDeleteJob)
    expect(SystemDeleteJob).to receive(:new).with(delete_entry['payload'], delete_entry['metadata'])
                                            .and_return(delete_runner)
    expect(delete_runner).to receive(:perform).with(delete_entry['payload'], delete_entry['metadata'])

    described_class.perform_now([delete_entry], kafka_metadata)
  end

  it 'defers a failed system suffix after processing other systems and logs Kafka coordinates' do
    a1 = entry(system_id: 'system-a', offset: 42)
    b1 = entry(system_id: 'system-b', offset: 43)
    a2 = entry(system_id: 'system-a', offset: 44)
    b2 = entry(system_id: 'system-b', offset: 45)
    entries = [a1, b1, a2, b2]
    failed_processor = instance_double(InventoryEventsProcessor, system_id: 'system-a')
    b1_processor = instance_double(InventoryEventsProcessor, system_id: 'system-b')
    a2_processor = instance_double(InventoryEventsProcessor, system_id: 'system-a')
    b2_processor = instance_double(InventoryEventsProcessor, system_id: 'system-b')
    expect(InventoryEventsProcessor).to receive(:new).with(a1, attempt: 1).ordered.and_return(failed_processor)
    expect(failed_processor).to receive(:process).ordered.and_raise(StandardError, 'boom')
    expect(InventoryEventsProcessor).to receive(:new).with(b1, attempt: 1).ordered.and_return(b1_processor)
    expect(b1_processor).to receive(:process).ordered
    expect(InventoryEventsProcessor).to receive(:new).with(a2, attempt: 1).ordered.and_return(a2_processor)
    expect(a2_processor).not_to receive(:process)
    expect(InventoryEventsProcessor).to receive(:new).with(b2, attempt: 1).ordered.and_return(b2_processor)
    expect(b2_processor).to receive(:process).ordered
    expect(InventoryEventsContinuationJob).to receive(:enqueue).with(
      [
        { 'entry' => a1, 'next_attempt' => 2 },
        { 'entry' => a2, 'next_attempt' => 1 }
      ], kafka_metadata
    ).ordered
    allow(Rails.logger).to receive(:error)

    described_class.perform_now(entries, kafka_metadata)

    expect(Rails.logger).to have_received(:error)
      .with('Failed to process inventory message at inventory:2:42: boom')
  end

  it 'keeps separate failed-system sequences in source order' do
    a1 = entry(system_id: 'system-a', offset: 42)
    b1 = entry(system_id: 'system-b', offset: 43)
    a2 = entry(system_id: 'system-a', offset: 44)
    b2 = entry(system_id: 'system-b', offset: 45)
    a3 = entry(system_id: 'system-a', offset: 46)
    b3 = entry(system_id: 'system-b', offset: 47)
    c1 = entry(system_id: 'system-c', offset: 48)
    entries = [a1, b1, c1, a2, b2, a3, b3]
    processors = entries.to_h do |batch_entry|
      id = batch_entry.dig('payload', 'host', 'id')
      [batch_entry, instance_double(InventoryEventsProcessor, system_id: id)]
    end
    allow(InventoryEventsProcessor).to receive(:new) do |batch_entry, attempt:|
      expect(attempt).to eq(1)
      processors.fetch(batch_entry)
    end
    expect(processors.fetch(a1)).to receive(:process).ordered.and_raise(StandardError, 'boom')
    expect(processors.fetch(b1)).to receive(:process).ordered.and_raise(StandardError, 'boom')
    expect(processors.fetch(c1)).to receive(:process).ordered
    [a2, b2, a3, b3].each do |blocked_entry|
      expect(processors.fetch(blocked_entry)).not_to receive(:process)
    end
    allow(Rails.logger).to receive(:error)
    expect(InventoryEventsContinuationJob).to receive(:enqueue).ordered.with(
      [
        { 'entry' => a1, 'next_attempt' => 2 },
        { 'entry' => a2, 'next_attempt' => 1 },
        { 'entry' => a3, 'next_attempt' => 1 }
      ], kafka_metadata
    )
    expect(InventoryEventsContinuationJob).to receive(:enqueue).ordered.with(
      [
        { 'entry' => b1, 'next_attempt' => 2 },
        { 'entry' => b2, 'next_attempt' => 1 },
        { 'entry' => b3, 'next_attempt' => 1 }
      ], kafka_metadata
    )

    described_class.perform_now(entries, kafka_metadata)
  end

  it 'falls back to one partition sequence on unknown identity, merging previously held entries by source order' do
    a1 = entry(system_id: 'system-a', offset: 42)
    b1 = entry(system_id: 'system-b', offset: 43)
    unknown = entry(system_id: nil, offset: 44)
    a2 = entry(system_id: 'system-a', offset: 45)
    b2 = entry(system_id: 'system-b', offset: 46)
    entries = [a1, b1, unknown, a2, b2]
    failed_a = instance_double(InventoryEventsProcessor, system_id: 'system-a')
    successful_b = instance_double(InventoryEventsProcessor, system_id: 'system-b')
    failed_unknown = instance_double(InventoryEventsProcessor, system_id: nil)
    expect(InventoryEventsProcessor).to receive(:new).with(a1, attempt: 1).ordered.and_return(failed_a)
    expect(failed_a).to receive(:process).ordered.and_raise(StandardError, 'a failed')
    expect(InventoryEventsProcessor).to receive(:new).with(b1, attempt: 1).ordered.and_return(successful_b)
    expect(successful_b).to receive(:process).ordered
    expect(InventoryEventsProcessor).to receive(:new).with(unknown, attempt: 1).ordered.and_return(failed_unknown)
    expect(failed_unknown).to receive(:process).ordered.and_raise(StandardError, 'unknown failed')
    expect(InventoryEventsProcessor).not_to receive(:new).with(a2, attempt: 1)
    expect(InventoryEventsProcessor).not_to receive(:new).with(b2, attempt: 1)
    allow(Rails.logger).to receive(:error)
    expect(InventoryEventsContinuationJob).to receive(:enqueue).with(
      [
        { 'entry' => a1, 'next_attempt' => 2 },
        { 'entry' => unknown, 'next_attempt' => 2 },
        { 'entry' => a2, 'next_attempt' => 1 },
        { 'entry' => b2, 'next_attempt' => 1 }
      ], kafka_metadata
    )

    described_class.perform_now(entries, kafka_metadata)
  end

  it 'propagates a false continuation enqueue result as EnqueueError' do
    failed_entry = entry(system_id: 'system-a', offset: 42)
    processor = instance_double(InventoryEventsProcessor, system_id: 'system-a')
    allow(InventoryEventsProcessor).to receive(:new).with(failed_entry, attempt: 1).and_return(processor)
    allow(processor).to receive(:process).and_raise(StandardError, 'boom')
    configured_job = double(perform_later: false)
    allow(InventoryEventsContinuationJob).to receive(:set)
      .with(wait: InventoryEventsContinuationJob::BACKOFF).and_return(configured_job)
    allow(Rails.logger).to receive(:error)

    expect do
      described_class.perform_now([failed_entry], kafka_metadata)
    end.to raise_error(InventoryEventsContinuationJob::EnqueueError)
  end

  it 'uses the inventory queue and metadata-derived single concurrency' do
    expect(described_class.queue_name).to eq('inventory')
    expect(described_class.good_job_concurrency_config[:perform_limit]).to eq(1)
    expect(described_class.new([], kafka_metadata).good_job_concurrency_key).to eq('inventory-partition:inventory:2')
  end
end
