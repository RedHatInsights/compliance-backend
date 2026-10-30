# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsProcessor do
  let(:metadata) { { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41 } }
  let(:payload) { { 'host' => { 'id' => SecureRandom.uuid } } }

  def entry(type, payload)
    { 'type' => type, 'payload' => payload, 'metadata' => metadata }
  end

  it 'dispatches created and updated events directly to the import job and propagates failures' do
    exception = StandardError.new('import failed')
    import_job = instance_double(SystemImportJob)
    expect(SystemImportJob).to receive(:new).with(payload, metadata).twice.and_return(import_job)
    expect(import_job).to receive(:perform).with(payload, metadata).twice.and_raise(exception)
    expect(import_job).not_to receive(:perform_now)

    %w[created updated].each do |type|
      expect { described_class.new(entry(type, payload), attempt: 1).process }
        .to raise_error { |raised| expect(raised).to equal(exception) }
    end
  end

  it 'dispatches delete events directly to the delete job and propagates failures' do
    delete_payload = { 'id' => SecureRandom.uuid }
    exception = ActiveRecord::RecordNotFound.new('delete failed')
    delete_job = instance_double(SystemDeleteJob)
    expect(SystemDeleteJob).to receive(:new).with(delete_payload, metadata).and_return(delete_job)
    expect(delete_job).to receive(:perform).with(delete_payload, metadata).and_raise(exception)
    expect(delete_job).not_to receive(:perform_now)

    expect { described_class.new(entry('delete', delete_payload), attempt: 1).process }
      .to raise_error { |raised| expect(raised).to equal(exception) }
  end

  it 'dispatches compliance reports to the report parser and propagates failures' do
    report_payload = payload.merge('platform_metadata' => { 'service' => 'compliance' })
    exception = StandardError.new('report failed')
    parser = instance_double(Kafka::ReportParser)
    expect(Kafka::ReportParser).to receive(:new).with(report_payload, Rails.logger).and_return(parser)
    expect(parser).to receive(:parse_reports).and_raise(exception)

    expect { described_class.new(entry('report', report_payload), attempt: 1).process }
      .to raise_error { |raised| expect(raised).to equal(exception) }
  end

  it 'logs and skips unknown non-compliance events' do
    unknown_payload = { 'platform_metadata' => { 'service' => 'inventory' } }
    allow(Rails.logger).to receive(:debug)

    described_class.new(entry('unknown', unknown_payload), attempt: 1).process

    expect(Rails.logger).to have_received(:debug).with("Skipped message of type 'unknown'")
  end

  it 'resolves system identifiers for import, delete, and compliance report entries' do
    expect(described_class.new(entry('created', payload), attempt: 1).system_id).to eq(payload.dig('host', 'id'))
    expect(described_class.new(entry('updated', payload), attempt: 1).system_id).to eq(payload.dig('host', 'id'))
    system_id = SecureRandom.uuid
    expect(described_class.new(entry('delete', { 'id' => system_id }), attempt: 1).system_id).to eq(system_id)

    report_payload = payload.merge('platform_metadata' => { 'service' => 'compliance' })
    expect(described_class.new(entry('report', report_payload), attempt: 1).system_id).to eq(payload.dig('host', 'id'))
  end

  it 'returns nil for missing or blank system identifiers' do
    expect(described_class.new(entry('created', {}), attempt: 1).system_id).to be_nil
    expect(described_class.new(entry('created', { 'host' => { 'id' => '' } }), attempt: 1).system_id).to be_nil
    expect(described_class.new(entry('delete', {}), attempt: 1).system_id).to be_nil
    expect(described_class.new(entry('delete', { 'id' => '  ' }), attempt: 1).system_id).to be_nil

    report_payload = { 'platform_metadata' => { 'service' => 'compliance' }, 'host' => { 'id' => nil } }
    expect(described_class.new(entry('report', report_payload), attempt: 1).system_id).to be_nil
  end

  it 'sets terminal import retry context only on attempt three' do
    early_jobs = 2.times.map { instance_double(SystemImportJob, perform: nil) }
    terminal_job = instance_double(SystemImportJob, perform: nil)
    expect(SystemImportJob).to receive(:new).with(payload, metadata).exactly(3).times
      .and_return(*early_jobs, terminal_job)

    early_jobs.each do |import_job|
      expect(import_job).not_to receive(:exception_executions=)
    end
    expect(terminal_job).to receive(:exception_executions=)
      .with(SystemImportJob::DATABASE_RETRY_HANDLER => 2)

    [1, 2].each do |attempt|
      described_class.new(entry('created', payload), attempt: attempt).process
    end

    described_class.new(entry('created', payload), attempt: 3).process
  end
end
