# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemImportJob do
  subject(:job) { described_class.perform_now(message) }

  let(:message) do
    {
      'type' => 'created',
      'host' => {
        'id' => SecureRandom.uuid,
        'insights_id' => SecureRandom.uuid
      }
    }
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

    expect(Kafka::SystemImporter).to have_received(:new).with(message, Rails.logger,
                                                               terminal_attempt: false)
    expect(importer).to have_received(:import)
    expect(Kafka::PolicySystemImporter).not_to have_received(:new)
    expect(Kafka::ReportParser).not_to have_received(:new)
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
    allow(Kafka::PolicySystemImporter).to receive(:new).and_return(instance_double(Kafka::PolicySystemImporter, import: nil))
    allow(Kafka::ReportParser).to receive(:new).and_return(instance_double(Kafka::ReportParser, parse_reports: nil))

    job

    expect(Kafka::SystemImporter).not_to have_received(:new)
    expect(Kafka::PolicySystemImporter).to have_received(:new)
    expect(Kafka::ReportParser).to have_received(:new)
  end
end
