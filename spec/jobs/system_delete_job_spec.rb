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
    allow(remover).to receive(:remove_system) do
      calls << :remove
      true
    end
    allow(cleaner).to receive(:cleanup_system) { calls << :cleanup }

    job

    expect(calls).to eq(%i[remove cleanup])
    expect(Kafka::SystemRemover).to have_received(:new).with(message, Rails.logger)
    expect(Kafka::DeletedSystemCleaner).to have_received(:new).with(message, Rails.logger)
  end

  it 'skips cleanup when the delete is stale' do
    user = FactoryBot.create(:user)
    policy = FactoryBot.create(:policy, account: user.account, supports_minors: [0])
    system = FactoryBot.create(
      :system, account: user.account, policy_id: policy.id, os_minor_version: 0, updated: Time.current
    )
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

RSpec.describe SystemDeleteJob, 'database idempotency' do
  let(:metadata) { { 'topic' => 'inventory', 'partition' => 2, 'offset' => 41 } }

  def delete_message(system_id:, org_id:, updated:)
    { 'type' => 'delete', 'id' => system_id, 'org_id' => org_id, 'updated' => updated }
  end

  def inventory_message(system_id:, account:, updated:, policy_id:)
    { 'type' => 'updated', 'host' => inventory_host(system_id, account, updated, policy_id) }
  end

  def inventory_host(system_id, account, updated, policy_id)
    {
      'id' => system_id, 'account' => account.org_id, 'org_id' => account.org_id,
      'display_name' => Faker::Internet.domain_name, 'groups' => [], 'tags' => [],
      'system_profile' => inventory_profile(policy_id), 'stale_timestamp' => updated,
      'created' => 5.days.ago.iso8601, 'updated' => updated, 'insights_id' => Faker::Internet.uuid
    }
  end

  def inventory_profile(policy_id)
    {
      'operating_system' => { 'major' => 7, 'minor' => 0 }, 'owner_id' => Faker::Internet.uuid,
      'image_builder' => { 'compliance_policy_id' => policy_id }
    }
  end

  it 'cleans related records for a current delete' do
    user = FactoryBot.create(:user)
    system = FactoryBot.create(
      :system, account: user.account, os_major_version: 7, os_minor_version: 0, updated: 4.days.ago
    )
    policy = FactoryBot.create(:policy, account: user.account, supports_minors: [0], system_id: system.id)
    test_result = FactoryBot.create(:test_result, system: system, report_id: policy.id)

    described_class.perform_now(delete_message(system_id: system.id, org_id: user.org_id,
                                               updated: 3.days.ago.iso8601), metadata)

    expect(System.where(id: system.id)).to be_empty
    expect(PolicySystem.where(system_id: system.id)).to be_empty
    expect(HistoricalTestResult.where(id: test_result.id)).to be_empty
  end

  it 'keeps resurrected related state when a later delete is stale' do
    user = FactoryBot.create(:user)
    system = FactoryBot.create(
      :system, account: user.account, os_major_version: 7, os_minor_version: 0, updated: 4.days.ago
    )
    policy = FactoryBot.create(:policy, account: user.account, supports_minors: [0], system_id: system.id)

    described_class.perform_now(delete_message(system_id: system.id, org_id: user.org_id,
                                               updated: 3.days.ago.iso8601), metadata)
    SystemImportJob.perform_now(
      inventory_message(system_id: system.id, account: user.account, updated: 2.days.ago.iso8601,
                        policy_id: policy.id),
      metadata
    )
    described_class.perform_now(delete_message(system_id: system.id, org_id: user.org_id,
                                               updated: 2.5.days.ago.iso8601), metadata)

    expect(System.where(id: system.id)).to exist
    expect(PolicySystem.where(system_id: system.id, policy_id: policy.id)).to exist
  end
end
