# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsContinuationJob do
  let(:kafka_metadata) do
    { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41, 'timestamp' => '2026-10-14T10:00:00Z' }
  end
  let(:entries) do
    3.times.map do |index|
      entry = {
        'type' => 'created',
        'payload' => { 'host' => { 'id' => SecureRandom.uuid } },
        'metadata' => kafka_metadata.merge('offset' => index + 42)
      }
      { 'entry' => entry, 'next_attempt' => 1 }
    end
  end

  it 'processes work items in order and enqueues nothing when all succeed' do
    processors = entries.map { instance_double(InventoryEventsProcessor, process: nil) }
    expect(InventoryEventsProcessor).to receive(:new).with(entries[0].fetch('entry'), attempt: 1)
                                                     .ordered.and_return(processors[0])
    expect(processors[0]).to receive(:process).ordered
    expect(InventoryEventsProcessor).to receive(:new).with(entries[1].fetch('entry'), attempt: 1)
                                                     .ordered.and_return(processors[1])
    expect(processors[1]).to receive(:process).ordered
    expect(InventoryEventsProcessor).to receive(:new).with(entries[2].fetch('entry'), attempt: 1)
                                                     .ordered.and_return(processors[2])
    expect(processors[2]).to receive(:process).ordered
    expect(described_class).not_to receive(:enqueue)

    described_class.new(entries, kafka_metadata).perform(entries, kafka_metadata)
  end

  it 'enqueues the failed entry and untouched suffix in their original order' do
    first, second, third = entries
    first_processor = instance_double(InventoryEventsProcessor, process: nil)
    second_processor = instance_double(InventoryEventsProcessor)
    expect(InventoryEventsProcessor).to receive(:new).with(first.fetch('entry'), attempt: 1)
                                                     .ordered.and_return(first_processor)
    expect(first_processor).to receive(:process).ordered
    expect(InventoryEventsProcessor).to receive(:new).with(second.fetch('entry'), attempt: 1)
                                                     .ordered.and_return(second_processor)
    expect(second_processor).to receive(:process).ordered.and_raise(StandardError, 'processor failed')
    expect(InventoryEventsProcessor).not_to receive(:new).with(third.fetch('entry'), attempt: 1)
    expect(described_class).to receive(:enqueue).with(
      [
        { 'entry' => second.fetch('entry'), 'next_attempt' => 2 },
        { 'entry' => third.fetch('entry'), 'next_attempt' => 1 }
      ], kafka_metadata
    ).ordered

    described_class.new(entries, kafka_metadata).perform(entries, kafka_metadata)
  end

  it 'increments a failed second attempt to the third attempt' do
    failed_work_item = { 'entry' => entries.first.fetch('entry'), 'next_attempt' => 2 }
    processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new).with(failed_work_item.fetch('entry'), attempt: 2)
                                                    .and_return(processor)
    allow(processor).to receive(:process).and_raise(StandardError, 'processor failed')
    expect(described_class).to receive(:enqueue).with(
      [{ 'entry' => failed_work_item.fetch('entry'), 'next_attempt' => 3 }], kafka_metadata
    )

    described_class.new([failed_work_item], kafka_metadata).perform([failed_work_item], kafka_metadata)
  end

  it 'raises on the third failure without enqueueing and preserves unresolved serialized arguments' do
    unresolved = [
      { 'entry' => entries.first.fetch('entry'), 'next_attempt' => 3 },
      { 'entry' => entries.second.fetch('entry'), 'next_attempt' => 1 }
    ]
    processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new).with(unresolved.first.fetch('entry'), attempt: 3)
                                                    .and_return(processor)
    allow(processor).to receive(:process).and_raise(ActiveRecord::Deadlocked, 'database failed')
    expect(described_class).not_to receive(:enqueue)
    job = described_class.new(unresolved, kafka_metadata)

    expect { job.perform(unresolved, kafka_metadata) }.to raise_error(described_class::AttemptsExhausted)

    expect(job.serialize.fetch('arguments')).to eq([unresolved, kafka_metadata])
  end

  it 'does not match terminal failures to inherited database retry handlers' do
    error = described_class::AttemptsExhausted.new('terminal')

    expect(matches_inherited_retry_handler?(error)).to be(false)
  end

  it 'raises EnqueueError when perform_later returns false' do
    stub_configured_enqueue(entries, kafka_metadata, result: false)

    expect { described_class.enqueue(entries, kafka_metadata) }
      .to raise_error(described_class::EnqueueError) do |error|
        expect(error.cause).to be_nil
        expect(matches_inherited_retry_handler?(error)).to be(false)
      end
  end

  it 'schedules continuations with the configured backoff and only the perform arguments' do
    original_adapter = described_class.queue_adapter
    test_adapter = ActiveJob::QueueAdapters::TestAdapter.new
    described_class.queue_adapter = test_adapter
    before_enqueue = Time.current

    job = described_class.enqueue(entries, kafka_metadata)

    expect(described_class::BACKOFF).to eq(30.seconds)
    expect(job.arguments).to eq([entries, kafka_metadata])
    serialized_job = test_adapter.enqueued_jobs.fetch(0)
    expect(serialized_job.fetch('arguments')).to eq([entries, kafka_metadata])
    expect(serialized_job.fetch(:at)).to be_between(
      (before_enqueue + described_class::BACKOFF).to_f,
      (Time.current + described_class::BACKOFF).to_f
    )
  ensure
    described_class.queue_adapter = original_adapter
  end

  it 'raises EnqueueError when perform_later returns nil' do
    stub_configured_enqueue(entries, kafka_metadata, result: nil)

    expect { described_class.enqueue(entries, kafka_metadata) }.to raise_error(described_class::EnqueueError)
  end

  it 're-raises an existing EnqueueError unchanged' do
    original_error = described_class::EnqueueError.new('already wrapped')
    stub_configured_enqueue(entries, kafka_metadata, error: original_error)

    expect { described_class.enqueue(entries, kafka_metadata) }
      .to raise_error(described_class::EnqueueError) { |error| expect(error).to equal(original_error) }
  end

  it 'wraps database enqueue errors without matching inherited retry handlers' do
    original_error = ActiveRecord::ConnectionFailed.new('database unavailable')
    stub_configured_enqueue(entries, kafka_metadata, error: original_error)

    expect { described_class.enqueue(entries, kafka_metadata) }
      .to raise_error(described_class::EnqueueError) { |error| expect(error.cause).to equal(original_error) }
    expect(matches_inherited_retry_handler?(described_class::EnqueueError.new('enqueue failed'))).to be(false)
  end

  it 'preserves the running job arguments when continuation enqueue fails' do
    work_items = [
      { 'entry' => entries.first.fetch('entry'), 'next_attempt' => 1 },
      { 'entry' => entries.second.fetch('entry'), 'next_attempt' => 1 }
    ]
    processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new).with(work_items.first.fetch('entry'), attempt: 1)
                                                    .and_return(processor)
    allow(processor).to receive(:process).and_raise(StandardError, 'processor failed')
    original_error = ActiveRecord::ConnectionFailed.new('database unavailable')
    continuation = [
      { 'entry' => work_items.first.fetch('entry'), 'next_attempt' => 2 },
      work_items.second
    ]
    stub_configured_enqueue(continuation, kafka_metadata, error: original_error)
    job = described_class.new(work_items, kafka_metadata)

    expect { job.perform(work_items, kafka_metadata) }
      .to raise_error(described_class::EnqueueError) { |error| expect(error.cause).to equal(original_error) }
    expect(job.serialize.fetch('arguments')).to eq([work_items, kafka_metadata])
  end

  it 'retains the original arguments for replay when enqueue fails after a successful prefix' do
    work_items = entries.map { |work_item| work_item.merge('next_attempt' => 1) }
    successful_processor = instance_double(InventoryEventsProcessor, process: nil)
    failed_processor = instance_double(InventoryEventsProcessor)
    allow(InventoryEventsProcessor).to receive(:new).with(work_items[0].fetch('entry'), attempt: 1)
                                                    .and_return(successful_processor)
    allow(InventoryEventsProcessor).to receive(:new).with(work_items[1].fetch('entry'), attempt: 1)
                                                    .and_return(failed_processor)
    allow(failed_processor).to receive(:process).and_raise(StandardError, 'processor failed')
    original_error = ActiveRecord::ConnectionFailed.new('database unavailable')
    continuation = [
      { 'entry' => work_items[1].fetch('entry'), 'next_attempt' => 2 },
      work_items[2]
    ]
    stub_configured_enqueue(continuation, kafka_metadata, error: original_error)
    job = described_class.new(work_items, kafka_metadata)

    expect { job.perform(work_items, kafka_metadata) }
      .to raise_error(described_class::EnqueueError) { |error| expect(error.cause).to equal(original_error) }
    expect(job.serialize.fetch('arguments')).to eq([work_items, kafka_metadata])
  end

  it 'uses the inventory queue and the batch topic-partition concurrency scope' do
    expect(described_class.queue_name).to eq('inventory')
    expect(described_class.good_job_concurrency_config[:perform_limit]).to eq(1)
    expect(described_class.new(entries, kafka_metadata).good_job_concurrency_key)
      .to eq('inventory-partition:inventory:2')
  end

  private

  def stub_configured_enqueue(*perform_arguments, result: nil, error: nil)
    configured_job = instance_double(ActiveJob::ConfiguredJob)
    allow(described_class).to receive(:set).with(wait: described_class::BACKOFF).and_return(configured_job)
    expectation = expect(configured_job).to receive(:perform_later).with(*perform_arguments)
    error ? expectation.and_raise(error) : expectation.and_return(result)
  end

  def matches_inherited_retry_handler?(error)
    described_class.rescue_handlers.any? do |class_name, _handler|
      error.is_a?(class_name.constantize)
    end
  end
end
