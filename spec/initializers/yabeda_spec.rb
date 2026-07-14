# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Compliance::TableSizeCollector do
  let(:existing_table_name) { "table_#{Faker::Lorem.unique.word}" }
  let(:dropped_table_name) { "table_#{Faker::Lorem.unique.word}" }
  let(:initial_existing_size) { Faker::Number.between(from: 100, to: 10_000) }
  let(:initial_dropped_size) { Faker::Number.between(from: 100, to: 10_000) }
  let(:updated_existing_size) { Faker::Number.between(from: 10_001, to: 20_000) }

  before do
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
  end

  it 'removes metrics for tables that no longer exist in the database' do
    # Simulate DB returning only 'existing_table'
    mock_result = [
      { 'table_name' => existing_table_name, 'size_bytes' => updated_existing_size.to_s }
    ]
    allow(@mock_connection).to receive(:execute).and_return(mock_result)

    # Trigger only the specific collector block
    described_class.collect

    # Verify Yabeda memory
    metric = Yabeda.compliance_db_table_size_bytes

    # dropped_table should be purged
    expect(metric.values.keys.map { |tags| tags[:table] }).to include(existing_table_name)
    expect(metric.values.keys.map { |tags| tags[:table] }).not_to include(dropped_table_name)

    # existing_table should be updated
    existing_tags = { application: 'compliance', qe: 0, source: 'basic', table: existing_table_name }
    expect(metric.values[existing_tags].value).to eq(updated_existing_size)
  end
end
