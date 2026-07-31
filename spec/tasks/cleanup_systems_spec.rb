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

  describe 'subtask: filter' do
    let(:user) { FactoryBot.create(:user) }

    def insert_inventory_host(sys)
      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO inventory.hosts_v1_1 (id, account, org_id, display_name, tags, updated, created, stale_timestamp, system_profile)
        VALUES ('#{sys.id}', '12345', '#{sys.org_id}', '#{sys.display_name}', '[]', '#{sys.updated.iso8601}', '#{sys.created.iso8601}', '#{sys.stale_timestamp.iso8601}', '#{sys.system_profile.to_json}')
      SQL
    end

    # 1. Valid/eligible system
    let!(:eligible_sys) do
      FactoryBot.create(
        :system,
        account: user.account,
        os_minor_version: 0,
        insights_id: Faker::Internet.uuid
      )
    end

    # 2. Ineligible: Missing insights_id
    let!(:missing_insights_sys) do
      FactoryBot.create(
        :system,
        account: user.account,
        os_minor_version: 0,
        insights_id: nil
      )
    end

    # 3. Ineligible: CentOS OS
    let!(:centos_sys) do
      FactoryBot.create(
        :system,
        account: user.account,
        os_minor_version: 0,
        insights_id: Faker::Internet.uuid,
        system_profile: { 'operating_system' => { 'name' => 'CentOS Linux', 'major' => 8, 'minor' => 4 } }
      )
    end

    # 4. Ineligible: host_type == 'edge'
    let!(:edge_sys) do
      sys = FactoryBot.build(:system, account: user.account, os_minor_version: 0, insights_id: Faker::Internet.uuid)
      sys.system_profile = sys.system_profile.merge('host_type' => 'edge')
      sys.save!
      insert_inventory_host(sys)
      sys
    end

    # 5. Ineligible: bootc booted image digest present
    let!(:bootc_sys) do
      sys = FactoryBot.build(:system, account: user.account, os_minor_version: 0, insights_id: Faker::Internet.uuid)
      sys.system_profile = sys.system_profile.merge(
        'bootc_status' => { 'booted' => { 'image_digest' => 'sha256:123' } }
      )
      sys.save!
      insert_inventory_host(sys)
      sys
    end

    it 'purges ineligible systems based on Kafka filter criteria' do
      expect(System.count).to eq(5)

      expect do
        suppress_stdout do
          ENV['SUBTASKS'] = 'filter'
          Rake::Task['systems:cleanup'].invoke
        end
      end.to change { System.count }.by(-4)

      expect(System.find_by(id: eligible_sys.id)).not_to be_nil
      expect(System.find_by(id: missing_insights_sys.id)).to be_nil
      expect(System.find_by(id: centos_sys.id)).to be_nil
      expect(System.find_by(id: edge_sys.id)).to be_nil
      expect(System.find_by(id: bootc_sys.id)).to be_nil
    end
  end
end
