# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemImportJob do
  subject(:job) { described_class.perform_now(message, metadata) }

  let(:metadata) do
    { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41, 'timestamp' => '2026-10-14T10:00:00Z' }
  end

  let(:message) do
    {
      'type' => 'created',
      'host' => {
        'id' => SecureRandom.uuid,
        'insights_id' => SecureRandom.uuid
      }
    }
  end

  it 'preserves Kafka metadata in the serialized job arguments' do
    serialized_arguments = described_class.new(message, metadata).serialize['arguments']

    expect(serialized_arguments.first).to include('type' => message['type'])
    expect(serialized_arguments.last).to include(
      'topic' => metadata['topic'], 'partition' => metadata['partition'],
      'offset' => metadata['offset'], 'timestamp' => metadata['timestamp']
    )
  end

  it 'uses the imports queue' do
    expect(described_class.queue_name).to eq('imports')
  end

  it 'imports an eligible host' do
    importer = instance_double(Kafka::SystemImporter, import: nil)
    allow(Kafka::SystemImporter).to receive(:new).and_return(importer)
    allow(Kafka::PolicySystemImporter).to receive(:new)
    allow(Kafka::ReportParser).to receive(:new)

    job

    expect(Kafka::SystemImporter).to have_received(:new).with(
      message, Rails.logger, terminal_attempt: false
    )
    expect(importer).to have_received(:import)
    expect(Kafka::PolicySystemImporter).not_to have_received(:new)
    expect(Kafka::ReportParser).not_to have_received(:new)
  end

  it 'marks the third database attempt as the terminal import attempt' do
    importer = instance_double(Kafka::SystemImporter, import: nil)
    allow(Kafka::SystemImporter).to receive(:new).and_return(importer)
    allow(Kafka::PolicySystemImporter).to receive(:new)
    allow(Kafka::ReportParser).to receive(:new)
    terminal_job = described_class.new(message, metadata)
    terminal_job.exception_executions = { described_class::DATABASE_RETRY_HANDLER => 2 }

    terminal_job.perform_now

    expect(Kafka::SystemImporter).to have_received(:new).with(
      message, Rails.logger, terminal_attempt: true
    )
  end

  it 'does not count concurrency retries as terminal import attempts' do
    importer = instance_double(Kafka::SystemImporter, import: nil)
    allow(Kafka::SystemImporter).to receive(:new).and_return(importer)
    allow(Kafka::PolicySystemImporter).to receive(:new)
    allow(Kafka::ReportParser).to receive(:new)
    concurrency_job = described_class.new(message, metadata)
    concurrency_job.executions = 3
    concurrency_job.exception_executions = {
      'GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError' => 3
    }

    concurrency_job.perform_now

    expect(Kafka::SystemImporter).to have_received(:new).with(
      message, Rails.logger, terminal_attempt: false
    )
  end

  it 'runs policy import when a policy id is present' do
    message['host']['system_profile'] = {
      'image_builder' => { 'compliance_policy_id' => SecureRandom.uuid }
    }
    allow(Kafka::SystemImporter).to receive(:new).and_return(instance_double(Kafka::SystemImporter, import: nil))
    policy_importer = instance_double(Kafka::PolicySystemImporter, import: nil)
    allow(Kafka::PolicySystemImporter).to receive(:new).and_return(policy_importer)

    job

    expect(policy_importer).to have_received(:import)
  end

  it 'runs report preparation for compliance events' do
    message['platform_metadata'] = { 'service' => 'compliance' }
    allow(Kafka::SystemImporter).to receive(:new).and_return(instance_double(Kafka::SystemImporter, import: nil))
    parser = instance_double(Kafka::ReportParser, parse_reports: nil)
    allow(Kafka::ReportParser).to receive(:new).and_return(parser)

    job

    expect(parser).to have_received(:parse_reports)
  end

  it 'preserves the existing independent policy/report branches for an ineligible host' do
    message['host']['insights_id'] = nil
    message['host']['system_profile'] = {
      'image_builder' => { 'compliance_policy_id' => SecureRandom.uuid }
    }
    message['platform_metadata'] = { 'service' => 'compliance' }
    allow(Kafka::SystemImporter).to receive(:new).and_return(instance_double(Kafka::SystemImporter, import: nil))
    allow(Kafka::PolicySystemImporter).to receive(:new).and_return(
      instance_double(Kafka::PolicySystemImporter, import: nil)
    )
    allow(Kafka::ReportParser).to receive(:new).and_return(
      instance_double(Kafka::ReportParser, parse_reports: nil)
    )

    job

    expect(Kafka::SystemImporter).not_to have_received(:new)
    expect(Kafka::PolicySystemImporter).to have_received(:new)
    expect(Kafka::ReportParser).to have_received(:new)
  end
end

RSpec.describe SystemImportJob, 'database idempotency' do
  let(:metadata) { { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41 } }

  def inventory_message(system_id:, account:, updated:, display_name: Faker::Internet.domain_name, policy_id: nil)
    { 'type' => 'updated', 'host' => inventory_host(system_id, account, updated, display_name, policy_id) }
  end

  def inventory_host(system_id, account, updated, display_name, policy_id)
    {
      'id' => system_id, 'account' => account.org_id, 'org_id' => account.org_id,
      'display_name' => display_name, 'groups' => [], 'tags' => [],
      'system_profile' => inventory_profile(policy_id), 'stale_timestamp' => updated,
      'created' => 5.days.ago.iso8601, 'updated' => updated, 'insights_id' => Faker::Internet.uuid
    }
  end

  def inventory_profile(policy_id)
    {
      'operating_system' => { 'major' => 7, 'minor' => 0 }, 'owner_id' => Faker::Internet.uuid,
      'image_builder' => { 'compliance_policy_id' => policy_id }
    }.compact
  end

  it 'does not duplicate a system or policy association when repeated' do
    account = FactoryBot.create(:account)
    system_id = Faker::Internet.uuid
    system = FactoryBot.create(:system, id: system_id, account: account, os_major_version: 7, os_minor_version: 0)
    policy = FactoryBot.create(:policy, account: account, supports_minors: [0], system_id: system.id)
    message = inventory_message(system_id: system.id, account: account, updated: 1.hour.ago.iso8601,
                                policy_id: policy.id)

    described_class.perform_now(message, metadata)
    described_class.perform_now(message, metadata)

    expect(System.unscoped.where(id: system.id).count).to eq(1)
    expect(PolicySystem.where(system_id: system.id, policy_id: policy.id).count).to eq(1)
  end

  it 'preserves newer system state when an older import runs later' do
    account = FactoryBot.create(:account)
    system_id = Faker::Internet.uuid
    newer_message = inventory_message(system_id: system_id, account: account, updated: 1.hour.ago.iso8601,
                                      display_name: 'newer-system')
    older_message = inventory_message(system_id: system_id, account: account, updated: 2.hours.ago.iso8601,
                                      display_name: 'older-system')

    described_class.perform_now(newer_message, metadata)
    described_class.perform_now(older_message, metadata)

    expect(System.find(system_id).display_name).to eq('newer-system')
  end
end
