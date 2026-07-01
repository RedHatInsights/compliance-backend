# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Yabeda table size metrics collect block' do
  before do
    # Mock connection
    @mock_connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    allow(ActiveRecord::Base).to receive(:connection).and_return(@mock_connection)

    # Seed initial data to simulate a previous run
    metric = Yabeda.compliance_db_table_size_bytes
    metric.set({ table: 'existing_table' }, 1000)
    metric.set({ table: 'dropped_table' }, 500)
  end

  it 'removes metrics for tables that no longer exist in the database' do
    # Simulate DB returning only 'existing_table'
    mock_result = [
      { 'table_name' => 'existing_table', 'size_bytes' => '1200' }
    ]
    allow(@mock_connection).to receive(:execute).and_return(mock_result)

    # Trigger collect block
    Yabeda.collectors.each(&:call)

    # Verify Yabeda memory
    metric = Yabeda.compliance_db_table_size_bytes

    # dropped_table should be purged
    expect(metric.values.keys.map { |tags| tags[:table] }).to include('existing_table')
    expect(metric.values.keys.map { |tags| tags[:table] }).not_to include('dropped_table')

    # existing_table should be updated
    existing_tags = { application: 'compliance', qe: 0, source: 'basic', table: 'existing_table' }
    expect(metric.values[existing_tags].value).to eq(1200)
  end
end
