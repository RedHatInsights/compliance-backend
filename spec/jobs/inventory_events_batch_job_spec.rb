# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsBatchJob do
  let(:kafka_metadata) do
    { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41, 'timestamp' => '2026-10-14T10:00:00Z' }
  end
  let(:import_payload) { { 'type' => 'created', 'host' => { 'id' => SecureRandom.uuid } } }
  let(:delete_payload) { { 'id' => SecureRandom.uuid } }
  let(:report_payload) { { 'type' => 'report', 'platform_metadata' => { 'service' => 'compliance' } } }
  let(:entry_metadata) { kafka_metadata.merge('offset' => 42) }

  it 'dispatches entries sequentially to their existing processors' do
    import_runner = instance_double(SystemImportJob)
    delete_runner = instance_double(SystemDeleteJob)
    report_parser = instance_double(Kafka::ReportParser)
    entries = [
      { 'type' => 'created', 'payload' => import_payload, 'metadata' => entry_metadata },
      { 'type' => 'delete', 'payload' => delete_payload, 'metadata' => entry_metadata },
      { 'type' => 'report', 'payload' => report_payload, 'metadata' => entry_metadata }
    ]

    expect(SystemImportJob).to receive(:new).with(import_payload, entry_metadata).ordered.and_return(import_runner)
    expect(import_runner).to receive(:perform_now).with(no_args).ordered
    expect(SystemDeleteJob).to receive(:new).with(delete_payload, entry_metadata).ordered.and_return(delete_runner)
    expect(delete_runner).to receive(:perform_now).with(no_args).ordered
    expect(Kafka::ReportParser).to receive(:new).with(report_payload, Rails.logger).ordered.and_return(report_parser)
    expect(report_parser).to receive(:parse_reports).ordered

    described_class.new(entries, kafka_metadata).perform(entries, kafka_metadata)
  end

  it 'logs and skips unknown non-compliance messages' do
    payload = { 'type' => 'unknown', 'platform_metadata' => { 'service' => 'inventory' } }
    metadata = kafka_metadata.merge('offset' => 42)
    allow(Rails.logger).to receive(:debug)

    described_class.perform_now([{ 'type' => 'unknown', 'payload' => payload, 'metadata' => metadata }], kafka_metadata)

    expect(Rails.logger).to have_received(:debug).with("Skipped message of type 'unknown'")
  end

  it 'continues after a per-entry StandardError and logs Kafka coordinates' do
    next_payload = { 'type' => 'created', 'host' => { 'id' => SecureRandom.uuid } }
    failed_runner = instance_double(SystemImportJob)
    next_runner = instance_double(SystemImportJob)
    entries = [
      { 'type' => 'created', 'payload' => import_payload, 'metadata' => entry_metadata },
      { 'type' => 'created', 'payload' => next_payload, 'metadata' => kafka_metadata.merge('offset' => 43) }
    ]
    expect(SystemImportJob).to receive(:new).with(import_payload, entry_metadata).ordered.and_return(failed_runner)
    expect(failed_runner).to receive(:perform_now).with(no_args).ordered.and_raise(StandardError, 'boom')
    expect(SystemImportJob).to receive(:new).with(next_payload, entries.last['metadata']).ordered.and_return(next_runner)
    expect(next_runner).to receive(:perform_now).with(no_args).ordered
    allow(Rails.logger).to receive(:error)

    described_class.perform_now(entries, kafka_metadata)

    expect(Rails.logger).to have_received(:error).with(a_string_including('inventory', '2', '42', 'boom'))
  end

  it 'routes a projected delete using its entry type and preserves metadata' do
    delete_runner = instance_double(SystemDeleteJob)
    expect(SystemDeleteJob).to receive(:new).with(delete_payload, entry_metadata).and_return(delete_runner)
    expect(delete_runner).to receive(:perform_now).with(no_args)

    described_class.perform_now([{ 'type' => 'delete', 'payload' => delete_payload, 'metadata' => entry_metadata }], kafka_metadata)
  end

  it 'preserves the import job retry lifecycle for transient failures' do
    payload = { 'type' => 'created', 'host' => { 'id' => SecureRandom.uuid, 'insights_id' => SecureRandom.uuid } }
    original_adapter = SystemImportJob.queue_adapter
    test_adapter = ActiveJob::QueueAdapters::TestAdapter.new
    SystemImportJob.queue_adapter = test_adapter
    importer = instance_double(Kafka::SystemImporter)
    allow(Kafka::SystemImporter).to receive(:new).and_return(importer)
    expect(importer).to receive(:import).and_raise(ActiveRecord::Deadlocked)

    described_class.perform_now(
      [{ 'type' => 'created', 'payload' => payload, 'metadata' => entry_metadata }], kafka_metadata
    )

    expect(test_adapter.enqueued_jobs.map { |job| job[:job] }).to eq([SystemImportJob])
  ensure
    SystemImportJob.queue_adapter = original_adapter
  end

  it 'does not enqueue a retry when an import succeeds' do
    payload = { 'type' => 'created', 'host' => { 'id' => SecureRandom.uuid, 'insights_id' => SecureRandom.uuid } }
    original_adapter = SystemImportJob.queue_adapter
    test_adapter = ActiveJob::QueueAdapters::TestAdapter.new
    SystemImportJob.queue_adapter = test_adapter
    importer = instance_double(Kafka::SystemImporter, import: nil)
    allow(Kafka::SystemImporter).to receive(:new).and_return(importer)

    described_class.perform_now(
      [{ 'type' => 'created', 'payload' => payload, 'metadata' => entry_metadata }], kafka_metadata
    )

    expect(test_adapter.enqueued_jobs).to be_empty
  ensure
    SystemImportJob.queue_adapter = original_adapter
  end

  it 'preserves the delete job retry lifecycle for transient failures' do
    original_adapter = SystemDeleteJob.queue_adapter
    test_adapter = ActiveJob::QueueAdapters::TestAdapter.new
    SystemDeleteJob.queue_adapter = test_adapter
    remover = instance_double(Kafka::SystemRemover)
    allow(Kafka::SystemRemover).to receive(:new).and_return(remover)
    expect(remover).to receive(:remove_system).and_raise(ActiveRecord::Deadlocked)

    described_class.perform_now(
      [{ 'type' => 'delete', 'payload' => delete_payload, 'metadata' => entry_metadata }], kafka_metadata
    )

    expect(test_adapter.enqueued_jobs.map { |job| job[:job] }).to eq([SystemDeleteJob])
  ensure
    SystemDeleteJob.queue_adapter = original_adapter
  end

  it 'uses the inventory queue and metadata-derived single concurrency' do
    expect(described_class.queue_name).to eq('inventory')
    expect(described_class.good_job_concurrency_config[:perform_limit]).to eq(1)
    expect(described_class.new([], kafka_metadata).good_job_concurrency_key).to eq('inventory-partition:inventory:2')
  end
end
