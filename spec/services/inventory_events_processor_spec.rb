# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsProcessor do
  let(:payload) { { 'host' => { 'id' => Faker::Internet.uuid } } }
  let(:metadata) { { 'topic' => Faker::Internet.domain_word, 'partition' => 1, 'offset' => 3 } }
  let(:entry) { { 'type' => type, 'payload' => payload, 'metadata' => metadata } }
  let(:type) { 'created' }

  it 'synchronously imports created events with terminal instrumentation' do
    job = SystemImportJob.new
    allow(job).to receive(:perform) do |actual_payload|
      expect(actual_payload).to eq(payload)
      expect(job.exception_executions).to eq(SystemImportJob::DATABASE_RETRY_HANDLER => 1)
      :result
    end
    allow(SystemImportJob).to receive(:new).with(no_args).and_return(job)

    expect(described_class.new(entry, attempt: 2).process).to eq(:result)
    expect(job.exception_executions).to eq(SystemImportJob::DATABASE_RETRY_HANDLER => 1)
    expect(job).to have_received(:perform).with(payload)
  end

  it 'synchronously imports updated events' do
    entry['type'] = 'updated'
    job = SystemImportJob.new
    allow(job).to receive(:perform)
    expect(SystemImportJob).to receive(:new).with(no_args).and_return(job)
    expect(job).to receive(:perform).with(payload)
    expect(SystemImportJob).not_to receive(:perform_later)
    described_class.new(entry).process
  end

  it 'synchronously deletes delete events' do
    entry['type'] = 'delete'
    job = instance_double(SystemDeleteJob, perform: :result)
    allow(SystemDeleteJob).to receive(:new).with(no_args).and_return(job)
    expect(job).to receive(:perform).with(payload)
    expect(SystemDeleteJob).not_to receive(:perform_later)
    expect(described_class.new(entry).process).to eq(:result)
  end

  it 'does not process unknown events' do
    entry['type'] = 'unknown'
    expect(Kafka::ReportParser).not_to receive(:new)
    expect(Rails.logger).not_to receive(:debug)
    expect(described_class.new(entry).process).to be_nil
  end
end
