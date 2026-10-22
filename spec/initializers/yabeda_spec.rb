# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Compliance::TableSizeCollector do
  let(:table_sizes) { Yabeda.compliance_db_table_size_bytes }

  let(:existing_table_name) { "table_#{Faker::Lorem.unique.word}" }
  let(:dropped_table_name) { "table_#{Faker::Lorem.unique.word}" }
  let(:initial_existing_size) { Faker::Number.between(from: 100, to: 10_000) }
  let(:initial_dropped_size) { Faker::Number.between(from: 100, to: 10_000) }
  let(:updated_existing_size) { Faker::Number.between(from: 10_001, to: 20_000) }

  before do
    described_class.instance_variable_set(:@last_collection_at, nil)

    # Mock connection
    @mock_connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    allow(ActiveRecord::Base).to receive(:connection).and_return(@mock_connection)

    # Seed initial data to simulate a previous run
    metric = Yabeda.compliance_db_table_size_bytes
    metric.set({ table: existing_table_name }, initial_existing_size)
    metric.set({ table: dropped_table_name }, initial_dropped_size)
  end

  after do
    Yabeda.compliance_db_table_size_bytes.values.clear
    described_class.instance_variable_set(:@last_collection_at, nil)
  end

  it 'caches table sizes for ten minutes within the process' do
    first_result = [{ 'table_name' => existing_table_name, 'size_bytes' => initial_existing_size.to_s }]
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(100.0, 101.0)
    expect(@mock_connection).to receive(:execute).once.and_return(first_result)

    described_class.collect
    described_class.collect

    tags = { application: 'compliance', qe: 0, source: 'basic', table: existing_table_name }
    expect(table_sizes.values[tags].value).to eq(initial_existing_size)
  end

  it 'refreshes table sizes once ten minutes have elapsed' do
    first_result = [{ 'table_name' => existing_table_name, 'size_bytes' => initial_existing_size.to_s }]
    later_result = [{ 'table_name' => existing_table_name, 'size_bytes' => updated_existing_size.to_s }]
    allow(Process).to receive(:clock_gettime)
      .with(Process::CLOCK_MONOTONIC)
      .and_return(100.0, 101.0, 700.0, 701.0, 702.0)
    expect(@mock_connection).to receive(:execute).twice.and_return(first_result, later_result)

    described_class.collect
    described_class.collect
    described_class.collect

    tags = { application: 'compliance', qe: 0, source: 'basic', table: existing_table_name }
    expect(table_sizes.values[tags].value).to eq(updated_existing_size)
  end

  it 'retries table-size collection after a failed query' do
    result = [{ 'table_name' => existing_table_name, 'size_bytes' => updated_existing_size.to_s }]
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(100.0, 200.0)
    allow(Rails.logger).to receive(:error)
    expect(@mock_connection).to receive(:execute).once.ordered.and_raise(ActiveRecord::ConnectionNotEstablished)
    expect(@mock_connection).to receive(:execute).once.ordered.and_return(result)

    described_class.collect
    described_class.collect

    tags = { application: 'compliance', qe: 0, source: 'basic', table: existing_table_name }
    expect(table_sizes.values[tags].value).to eq(updated_existing_size)
  end

  it 'removes metrics for tables that no longer exist in the database' do
    # Simulate DB returning only 'existing_table'
    mock_result = [
      { 'table_name' => existing_table_name, 'size_bytes' => updated_existing_size.to_s }
    ]
    allow(@mock_connection).to receive(:execute).and_return(mock_result)

    # Spy on .set calls during the collection
    allow(Yabeda.compliance_db_table_size_bytes).to receive(:set).and_call_original

    # Trigger only the specific collector block
    described_class.collect

    # Verify that the dropped table was set to 0 before deletion
    expect(Yabeda.compliance_db_table_size_bytes).to have_received(:set).with(
      { application: 'compliance', qe: 0, source: 'basic', table: dropped_table_name },
      0
    )

    # Verify Yabeda memory
    metric = Yabeda.compliance_db_table_size_bytes

    # dropped_table should be purged from memory
    expect(metric.values.keys.map { |tags| tags[:table] }).to include(existing_table_name)
    expect(metric.values.keys.map { |tags| tags[:table] }).not_to include(dropped_table_name)

    # existing_table should be updated
    existing_tags = { application: 'compliance', qe: 0, source: 'basic', table: existing_table_name }
    expect(metric.values[existing_tags].value).to eq(updated_existing_size)
  end
end

RSpec.describe Compliance::GoodJobQueueDepthCollector do
  let(:active_queue_name) { "queue_#{Faker::Lorem.unique.word}" }
  let(:stale_queue_name) { "queue_#{Faker::Lorem.unique.word}" }
  let(:initial_active_count) { Faker::Number.between(from: 1, to: 10) }
  let(:initial_stale_count) { Faker::Number.between(from: 1, to: 10) }
  let(:updated_active_count) { Faker::Number.between(from: 11, to: 20) }

  before do
    metric = Yabeda.good_job_queue_depth
    metric.set({ queue: active_queue_name }, initial_active_count)
    metric.set({ queue: stale_queue_name }, initial_stale_count)
  end

  after do
    Yabeda.good_job_queue_depth.values.clear
  end

  it 'removes metrics for queues with no unfinished jobs' do
    relation = instance_double(ActiveRecord::Relation)
    allow(GoodJob::Job).to receive(:where).with(finished_at: nil).and_return(relation)
    allow(relation).to receive(:group).with(:queue_name).and_return(relation)
    allow(relation).to receive(:count).and_return({ active_queue_name => updated_active_count })

    allow(Yabeda.good_job_queue_depth).to receive(:set).and_call_original

    described_class.collect

    expect(Yabeda.good_job_queue_depth).to have_received(:set).with(
      { application: 'compliance', qe: 0, source: 'basic', queue: stale_queue_name },
      0
    )

    metric = Yabeda.good_job_queue_depth

    expect(metric.values.keys.map { |tags| tags[:queue] }).to include(active_queue_name)
    expect(metric.values.keys.map { |tags| tags[:queue] }).not_to include(stale_queue_name)

    active_tags = { application: 'compliance', qe: 0, source: 'basic', queue: active_queue_name }
    expect(metric.values[active_tags].value).to eq(updated_active_count)
  end

  it 'uses "default" for the nil queue name' do
    relation = instance_double(ActiveRecord::Relation)
    allow(GoodJob::Job).to receive(:where).with(finished_at: nil).and_return(relation)
    allow(relation).to receive(:group).with(:queue_name).and_return(relation)
    allow(relation).to receive(:count).and_return({ nil => 3 })

    described_class.collect

    default_tags = { application: 'compliance', qe: 0, source: 'basic', queue: 'default' }
    expect(Yabeda.good_job_queue_depth.values[default_tags].value).to eq(3)
  end

  it 'rescues and logs errors instead of raising' do
    allow(GoodJob::Job).to receive(:where).and_raise(ActiveRecord::ConnectionNotEstablished)
    expect(Rails.logger).to receive(:error).with(/Failed to collect GoodJob queue depth metrics/)

    expect { described_class.collect }.not_to raise_error
  end
end
