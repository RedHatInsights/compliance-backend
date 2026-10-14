# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemDeleteJob do
  subject(:job) { described_class.perform_now(message, metadata) }

  let(:metadata) { { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41 } }

  let(:message) do
    {
      'type' => 'delete',
      'id' => SecureRandom.uuid,
      'org_id' => Faker::Number.number(digits: 6).to_s
    }
  end

  it 'uses the deletes queue' do
    expect(described_class.queue_name).to eq('deletes')
  end

  it 'runs the remover before the cleaner' do
    calls = []
    remover = instance_double(Kafka::SystemRemover)
    cleaner = instance_double(Kafka::DeletedSystemCleaner)
    allow(Kafka::SystemRemover).to receive(:new).and_return(remover)
    allow(Kafka::DeletedSystemCleaner).to receive(:new).and_return(cleaner)
    allow(remover).to receive(:remove_system) { calls << :remove; true }
    allow(cleaner).to receive(:cleanup_system) { calls << :cleanup }

    job

    expect(calls).to eq(%i[remove cleanup])
    expect(Kafka::SystemRemover).to have_received(:new).with(message, Rails.logger)
    expect(Kafka::DeletedSystemCleaner).to have_received(:new).with(message, Rails.logger)
  end


  it 'skips cleanup when the delete is stale' do
    user = FactoryBot.create(:user)
    policy = FactoryBot.create(:policy, account: user.account, supports_minors: [0])
    system = FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0,
                               updated: Time.current)
    test_result = FactoryBot.create(:test_result, system: system, report_id: policy.id)
    stale_message = {
      'type' => 'delete',
      'id' => system.id,
      'org_id' => user.org_id,
      'updated' => 1.day.ago.utc.iso8601
    }

    described_class.perform_now(stale_message, metadata)

    expect(system.reload.deleted_at).to be_nil
    expect(PolicySystem.exists?(system_id: system.id)).to be(true)
    expect(HistoricalTestResult.exists?(id: test_result.id)).to be(true)
  end

  it 'propagates remover failures without running cleanup' do
    remover = instance_double(Kafka::SystemRemover)
    cleaner = instance_double(Kafka::DeletedSystemCleaner)
    allow(Kafka::SystemRemover).to receive(:new).and_return(remover)
    allow(Kafka::DeletedSystemCleaner).to receive(:new).and_return(cleaner)
    allow(remover).to receive(:remove_system).and_raise(ActiveRecord::RecordNotFound)
    allow(cleaner).to receive(:cleanup_system)

    expect { job }.to raise_error(ActiveRecord::RecordNotFound)
    expect(cleaner).not_to have_received(:cleanup_system)
  end
end
