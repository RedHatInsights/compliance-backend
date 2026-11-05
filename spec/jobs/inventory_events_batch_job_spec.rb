# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsBatchJob do
  let(:metadata) { { 'topic' => Faker::Internet.domain_word, 'partition' => 2, 'offset' => 41 } }
  let(:first_entry) { { 'type' => 'created', 'payload' => { 'host' => { 'id' => Faker::Internet.uuid } }, 'metadata' => metadata } }
  let(:second_entry) { { 'type' => 'updated', 'payload' => { 'host' => { 'id' => Faker::Internet.uuid } }, 'metadata' => metadata } }
  let(:third_entry) { { 'type' => 'updated', 'payload' => { 'host' => { 'id' => Faker::Internet.uuid } }, 'metadata' => metadata } }

  it 'processes entries in their original order' do
    first_processor = instance_double(InventoryEventsProcessor)
    second_processor = instance_double(InventoryEventsProcessor)
    expect(InventoryEventsProcessor).to receive(:new).with(first_entry, attempt: 1).ordered.and_return(first_processor)
    expect(first_processor).to receive(:process).ordered
    expect(InventoryEventsProcessor).to receive(:new)
      .with(second_entry, attempt: 1).ordered.and_return(second_processor)
    expect(second_processor).to receive(:process).ordered

    described_class.perform_now([first_entry, second_entry])
  end

  it 'continues processing later entries and retries only failed entries' do
    failure_message = Faker::Lorem.sentence
    first_processor = instance_double(InventoryEventsProcessor)
    second_processor = instance_double(InventoryEventsProcessor)
    third_processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new).with(first_entry, attempt: 1).and_return(first_processor)
    allow(InventoryEventsProcessor).to receive(:new).with(second_entry, attempt: 1).and_return(second_processor)
    allow(InventoryEventsProcessor).to receive(:new).with(third_entry, attempt: 1).and_return(third_processor)
    allow(first_processor).to receive(:process).and_raise(StandardError, failure_message)
    expect(second_processor).to receive(:process).ordered
    expect(third_processor).to receive(:process).ordered
    job = described_class.new([first_entry, second_entry, third_entry], 1)

    expect { job.perform(*job.arguments) }.to raise_error(described_class::BatchEntryError, failure_message)
    expect(job.arguments).to eq([[first_entry], 2])
  end

  it 'continues processing later entries after the final retry attempt' do
    failure_message = Faker::Lorem.sentence
    first_processor = instance_double(InventoryEventsProcessor)
    second_processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new)
      .with(first_entry, attempt: described_class::MAX_ATTEMPTS).and_return(first_processor)
    allow(InventoryEventsProcessor).to receive(:new)
      .with(second_entry, attempt: described_class::MAX_ATTEMPTS).and_return(second_processor)
    allow(first_processor).to receive(:process).and_raise(StandardError, failure_message)
    expect(second_processor).to receive(:process)
    job = described_class.new([first_entry, second_entry], described_class::MAX_ATTEMPTS)

    expect { job.perform(*job.arguments) }.to raise_error(described_class::BatchEntryError, failure_message)
    expect(job.arguments).to eq([[first_entry], described_class::MAX_ATTEMPTS + 1])
  end

  it 'preserves the failed entry for retry after the final attempt' do
    failure_message = Faker::Lorem.sentence
    first_processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new)
      .with(first_entry, attempt: described_class::MAX_ATTEMPTS).and_return(first_processor)
    allow(first_processor).to receive(:process).and_raise(StandardError, failure_message)
    job = described_class.new([first_entry], described_class::MAX_ATTEMPTS)

    expect { job.perform(*job.arguments) }.to raise_error(described_class::BatchEntryError, failure_message)
    expect(job.arguments).to eq([[first_entry], described_class::MAX_ATTEMPTS + 1])
  end
end
