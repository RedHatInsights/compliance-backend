# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'systems:cleanup task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  # Suppress task stdout outputs
  def suppress_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  before do
    # Re-enable the task before each test to allow multiple executions
    Rake::Task['systems:cleanup'].reenable
  end

  describe 'subtask: deleted' do
    let(:user) { FactoryBot.create(:v2_user) }
    let(:policy) { FactoryBot.create(:v2_policy, account: user.account, supports_minors: [0]) }
    let(:system) { FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0) }

    let!(:stale_tombstone) do
      FactoryBot.create(
        :kafka_system,
        id: system.id,
        account: '12345',
        org_id: user.org_id,
        deleted_at: 15.days.ago
      )
    end

    let!(:fresh_tombstone) do
      FactoryBot.create(
        :kafka_system,
        id: SecureRandom.uuid,
        account: '12345',
        org_id: user.org_id,
        deleted_at: 5.days.ago
      )
    end

    let!(:test_result) { FactoryBot.create(:v2_test_result, system: system, report_id: policy.id) }

    it 'purges old soft-deleted tombstones and related records but preserves fresh ones' do
      expect(KafkaSystem.unscoped.count).to eq(2)
      expect(KafkaSystem.count).to eq(0)

      expect do
        suppress_stdout do
          ENV['SUBTASKS'] = 'deleted'
          ENV['DELETED_RETENTION_DAYS'] = '14'
          Rake::Task['systems:cleanup'].invoke
        end
      end.to change { KafkaSystem.unscoped.count }.by(-1)
         .and(change { V2::HistoricalTestResult.where(system_id: system.id).count }.from(1).to(0))
                                                  .and(change { policy.systems.count }.from(1).to(0))

      expect(KafkaSystem.unscoped.find_by(id: fresh_tombstone.id)).not_to be_nil
      expect(KafkaSystem.unscoped.find_by(id: stale_tombstone.id)).to be_nil
    end
  end
end
