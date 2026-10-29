# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemDeleteJob do
  subject(:job) { described_class.perform_now(message) }

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
    delete_job = described_class.new(message)
    expect(delete_job).to receive(:soft_delete_system).ordered.and_return(true)
    expect(delete_job).to receive(:cleanup_system_relations).ordered

    delete_job.perform_now
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

    described_class.perform_now(stale_message)

    expect(system.reload.deleted_at).to be_nil
    expect(PolicySystem.exists?(system_id: system.id)).to be(true)
    expect(HistoricalTestResult.exists?(id: test_result.id)).to be(true)
  end

  it 'propagates remover failures without running cleanup' do
    delete_job = described_class.new(message)
    allow(delete_job).to receive(:soft_delete_system).and_raise(ActiveRecord::RecordNotFound)
    allow(delete_job).to receive(:cleanup_system_relations)

    expect { delete_job.perform_now }.to raise_error(ActiveRecord::RecordNotFound)
    expect(delete_job).not_to have_received(:cleanup_system_relations)
  end

  describe '#soft_delete_system' do
    let(:job) { described_class.new }
    let(:system_id) { Faker::Internet.uuid }
    let(:org_id) { Faker::Number.number(digits: 6).to_s }
    let(:account) { FactoryBot.create(:account, org_id: org_id) }
    let!(:system_record) { FactoryBot.create(:system, id: system_id, account: account, updated: 2.days.ago) }
    let(:message) { { 'id' => system_id, 'org_id' => org_id } }

    before do
      job.instance_variable_set(:@message, message)
      job.instance_variable_set(:@id, system_id)
      job.instance_variable_set(:@org_id, org_id)
    end

    it 'soft-deletes the system' do
      expect(Rails.logger).to receive(:audit_success).with(/Soft-deleted system/)

      expect(job.send(:soft_delete_system)).to be(true)
      expect(System.unscoped.find(system_id).deleted_at).not_to be_nil
      expect(System.count).to eq(0)
    end

    it 'uses the delete event timestamp' do
      message['updated'] = 1.day.ago.utc.iso8601

      job.send(:soft_delete_system)

      expect(System.unscoped.find(system_id).deleted_at).to eq(Time.zone.parse(message['updated']))
    end

    it 'logs and falls back to the current time for an invalid timestamp' do
      message['updated'] = 'invalid-timestamp-string'
      expect(Rails.logger).to receive(:warn).with(/Failed to parse timestamp 'invalid-timestamp-string'/)

      job.send(:soft_delete_system)

      expect(System.unscoped.find(system_id).deleted_at).not_to be_nil
    end

    it 'leaves a newer system active' do
      system_record.update!(updated: Time.current)
      message['updated'] = 1.day.ago.utc.iso8601
      expect(Rails.logger).to receive(:info).with(/Ignored stale delete event/)

      expect(job.send(:soft_delete_system)).to be(false)
      expect(system_record.reload.deleted_at).to be_nil
    end

    it 'counts stale delete events' do
      system_record.update!(updated: Time.current)
      message['updated'] = 1.day.ago.utc.iso8601

      expect { job.send(:soft_delete_system) }
        .to increment_yabeda_counter(Yabeda.compliance_system_delete_noop_total).by(1)
    end

    it 'logs and re-raises deletion failures' do
      allow(System).to receive(:unscoped).and_raise(ActiveRecord::ActiveRecordError, 'db error')
      expect(Rails.logger).to receive(:audit_fail).with(/Failed to soft-delete system.*db error/)

      expect { job.send(:soft_delete_system) }.to raise_error(ActiveRecord::ActiveRecordError, 'db error')
    end
  end

  describe '#cleanup_system_relations' do
    let(:job) { described_class.new }
    let(:user) { FactoryBot.create(:user) }
    let(:policy) { FactoryBot.create(:policy, account: user.account, supports_minors: [0]) }
    let(:system) { FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0) }
    let!(:test_result) { FactoryBot.create(:test_result, system: system, report_id: policy.id) }
    let!(:rule_result) { FactoryBot.create(:rule_result, test_result: test_result) }
    let(:message) { { 'id' => system.id, 'org_id' => user.org_id } }

    before do
      job.instance_variable_set(:@id, message['id'])
      job.instance_variable_set(:@org_id, message['org_id'])
    end

    it 'removes test results, rule results, and policy associations' do
      expect(Rails.logger).to receive(:audit_success).with(
        "[#{user.org_id}] Deleted related records for System #{system.id}"
      )

      expect { job.send(:cleanup_system_relations) }.to(
        change { HistoricalTestResult.where(system_id: system.id).count }.from(1).to(0)
        .and(change { RuleResult.where(id: rule_result.id).count }.from(1).to(0))
        .and(change { PolicySystem.where(system_id: system.id).count }.from(1).to(0))
      )
    end

    it 'does not remove records for another system under the same policy' do
      extra_system = FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0)
      extra_test_result = FactoryBot.create(:test_result, system: extra_system, report_id: policy.id)
      extra_rule_result = FactoryBot.create(:rule_result, test_result: extra_test_result)
      expect(Rails.logger).to receive(:audit_success).with(
        "[#{user.org_id}] Deleted related records for System #{system.id}"
      )

      expect { job.send(:cleanup_system_relations) }.to(
        change { HistoricalTestResult.where(system_id: system.id).count }.from(1).to(0)
        .and(change { policy.systems.count }.from(2).to(1))
      )

      expect(HistoricalTestResult.where(id: extra_test_result.id)).to exist
      expect(RuleResult.where(id: extra_rule_result.id)).to exist
      expect(System.where(id: extra_system.id)).to exist
    end

    it 'does not log cleanup when no related records exist' do
      lonely_system = FactoryBot.create(:system, account: user.account, os_minor_version: 0)
      message['id'] = lonely_system.id
      job.instance_variable_set(:@id, lonely_system.id)
      expect(Rails.logger).not_to receive(:audit_success)

      expect { job.send(:cleanup_system_relations) }.not_to change(System, :count)
    end

    it 'raises after logging a cleanup failure' do
      allow(job).to receive(:remove_related).and_raise(StandardError)
      expect(Rails.logger).to receive(:audit_fail).with(
        "[#{user.org_id}] Failed to delete related records for System #{system.id}: StandardError"
      )

      expect { job.send(:cleanup_system_relations) }.to raise_error(StandardError)
    end
  end
end

RSpec.describe SystemDeleteJob, 'database idempotency' do
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
                                               updated: 3.days.ago.iso8601))

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
                                               updated: 3.days.ago.iso8601))
    SystemImportJob.perform_now(
      inventory_message(system_id: system.id, account: user.account, updated: 2.days.ago.iso8601,
                        policy_id: policy.id)
    )
    described_class.perform_now(delete_message(system_id: system.id, org_id: user.org_id,
                                               updated: 2.5.days.ago.iso8601))

    expect(System.where(id: system.id)).to exist
    expect(PolicySystem.where(system_id: system.id, policy_id: policy.id)).to exist
  end
end
