# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'systems:cleanup task' do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  # Capture task stdout outputs
  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def suppress_stdout(&block)
    capture_stdout(&block)
  end

  let(:account) { Faker::Number.number(digits: 5).to_s }

  ENV_KEYS = %w[
    SUBTASKS
    DELETED_RETENTION_DAYS
    STALE_CLEANUP_ENABLED
    STALE_RETENTION_DAYS
    BATCH_SIZE
  ].freeze

  around do |example|
    original_envs = ENV_KEYS.to_h { |k| [k, ENV.fetch(k, nil)] }
    begin
      example.run
    ensure
      ENV_KEYS.each do |key|
        if original_envs[key].nil?
          ENV.delete(key)
        else
          ENV[key] = original_envs[key]
        end
      end
    end
  end

  before do
    # Re-enable the task before each test to allow multiple executions
    Rake::Task['systems:cleanup'].reenable
  end

  describe 'subtask: deleted' do
    let(:user) { FactoryBot.create(:user) }
    let(:policy) { FactoryBot.create(:policy, account: user.account, supports_minors: [0]) }

    # rubocop:disable Rails/SkipsModelValidations
    let!(:stale_tombstone) do
      sys = FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0)
      sys.update_column(:deleted_at, 15.days.ago)
      sys
    end

    let!(:fresh_tombstone) do
      sys = FactoryBot.create(:system, account: user.account, os_minor_version: 0)
      sys.update_column(:deleted_at, 5.days.ago)
      sys
    end
    # rubocop:enable Rails/SkipsModelValidations

    let!(:test_result) { FactoryBot.create(:test_result, system: stale_tombstone, report_id: policy.id) }

    it 'purges old soft-deleted tombstones and related records but preserves fresh ones' do
      expect(System.unscoped.count).to eq(2)
      expect(System.count).to eq(0)

      stale_id = stale_tombstone.id
      expect do
        suppress_stdout do
          ENV['SUBTASKS'] = 'deleted'
          ENV['DELETED_RETENTION_DAYS'] = '14'
          Rake::Task['systems:cleanup'].invoke
        end
      end.to change { System.unscoped.count }.by(-1)
                                             .and(change { HistoricalTestResult.where(system_id: stale_id).count }
                                                    .from(1).to(0))
                                             .and(change { policy.policy_systems.count }.from(1).to(0))

      expect(System.unscoped.find_by(id: fresh_tombstone.id)).not_to be_nil
      expect(System.unscoped.find_by(id: stale_tombstone.id)).to be_nil
    end
  end

  describe 'subtask: stale' do
    let(:user) { FactoryBot.create(:user) }
    let(:policy) { FactoryBot.create(:policy, account: user.account, supports_minors: [0]) }

    # rubocop:disable Rails/SkipsModelValidations
    let!(:stale_system) do
      sys = FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0)
      sys.update_column(:stale_timestamp, 35.days.ago)
      sys
    end

    let!(:fresh_system) do
      sys = FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0)
      sys.update_column(:stale_timestamp, 10.days.ago)
      sys
    end
    # rubocop:enable Rails/SkipsModelValidations

    context 'when stale cleanup is disabled (default)' do
      it 'does not purge any systems' do
        expect do
          suppress_stdout do
            ENV['SUBTASKS'] = 'stale'
            ENV['STALE_CLEANUP_ENABLED'] = 'false'
            Rake::Task['systems:cleanup'].invoke
          end
        end.not_to(change { System.count })
      end
    end

    context 'when stale cleanup is enabled' do
      it 'purges stale systems older than retention threshold' do
        expect do
          suppress_stdout do
            ENV['SUBTASKS'] = 'stale'
            ENV['STALE_CLEANUP_ENABLED'] = 'true'
            ENV['STALE_RETENTION_DAYS'] = '30'
            Rake::Task['systems:cleanup'].invoke
          end
        end.to change { System.count }.by(-1)

        expect(System.find_by(id: fresh_system.id)).not_to be_nil
        expect(System.find_by(id: stale_system.id)).to be_nil
      end
    end
  end

  describe 'unsupported subtasks' do
    let(:user) { FactoryBot.create(:user) }
    let!(:system) { FactoryBot.create(:system, account: user.account, os_minor_version: 0) }

    it 'logs a warning for unsupported subtasks and does not purge systems' do
      output = nil
      expect do
        output = capture_stdout do
          ENV['SUBTASKS'] = 'filter,unknown'
          Rake::Task['systems:cleanup'].invoke
        end
      end.not_to(change { System.count })

      expected_warning = 'Unsupported subtasks provided: filter, unknown. Supported subtasks are: deleted, stale.'
      expect(output).to include(expected_warning)
      expect(System.find_by(id: system.id)).not_to be_nil
    end
  end
end
