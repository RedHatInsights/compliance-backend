# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsProcessor do
  let(:payload) { { 'host' => { 'id' => Faker::Internet.uuid } } }
  let(:metadata) { { 'topic' => Faker::Internet.domain_word, 'partition' => 1, 'offset' => 3 } }
  let(:entry) { { 'type' => type, 'payload' => payload, 'metadata' => metadata } }
  let(:type) { 'created' }

  it 'synchronously imports created events' do
    job = instance_double(SystemImportJob, perform: :result)
    allow(SystemImportJob).to receive(:new).with(no_args).and_return(job)

    expect(described_class.new(entry).process).to eq(:result)
    expect(job).to have_received(:perform).with(payload)
  end

  it 'synchronously imports updated events' do
    entry['type'] = 'updated'
    job = instance_double(SystemImportJob, perform: :result)
    allow(SystemImportJob).to receive(:new).with(no_args).and_return(job)

    expect(described_class.new(entry).process).to eq(:result)
    expect(job).to have_received(:perform).with(payload)
  end

  it 'synchronously deletes delete events' do
    entry['type'] = 'delete'
    job = instance_double(SystemDeleteJob, perform: :result)
    allow(SystemDeleteJob).to receive(:new).with(no_args).and_return(job)

    expect(described_class.new(entry).process).to eq(:result)
    expect(job).to have_received(:perform).with(payload)
  end

  it 'does not process unknown events' do
    entry['type'] = 'unknown'
    expect(Kafka::ReportParser).not_to receive(:new)
    expect(Rails.logger).not_to receive(:debug)

    expect(described_class.new(entry).process).to be_nil
  end
end
