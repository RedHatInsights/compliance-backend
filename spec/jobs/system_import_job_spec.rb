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
    import_job = described_class.new(message)
    expect(import_job).to receive(:import_system).and_return(true)
    expect(import_job).not_to receive(:import_policy_system)

    import_job.perform_now
  end

  it 'marks the third database attempt as the terminal import attempt' do
    terminal_job = described_class.new(message)
    terminal_job.exception_executions = { described_class::DATABASE_RETRY_HANDLER => 2 }

    expect(terminal_job.send(:terminal_import_attempt?)).to be(true)
  end

  it 'does not count concurrency retries as terminal import attempts' do
    concurrency_job = described_class.new(message)
    concurrency_job.executions = 3
    concurrency_job.exception_executions = {
      'GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError' => 3
    }

    expect(concurrency_job.send(:terminal_import_attempt?)).to be(false)
  end

  it 'imports the policy association and reports for an eligible host' do
    message['host']['system_profile'] = {
      'image_builder' => { 'compliance_policy_id' => SecureRandom.uuid }
    }
    message['platform_metadata'] = { 'service' => 'compliance' }
    report_parser = instance_double(Kafka::ReportParser, parse_reports: nil)
    allow(Kafka::ReportParser).to receive(:new).and_return(report_parser)
    import_job = described_class.new(message)
    expect(import_job).to receive(:import_system).and_return(true)
    expect(import_job).to receive(:import_policy_system)

    import_job.perform_now

    expect(report_parser).to have_received(:parse_reports)
  end

  it 'skips policy import and report parsing for an invalid host' do
    message['host']['tags'] = [Faker::Lorem.word]
    message['host']['system_profile'] = {
      'image_builder' => { 'compliance_policy_id' => SecureRandom.uuid }
    }
    message['platform_metadata'] = { 'service' => 'compliance' }
    expect(Kafka::ReportParser).not_to receive(:new)

    expect { described_class.perform_now(message) }
      .to increment_yabeda_counter(Yabeda.compliance_system_import_invalid_total).by(1)
    expect(PolicySystem.count).to eq(0)
  end

  describe '#import_system' do
    let(:updated_time) { Time.current.iso8601 }
    let(:owner_id) { Faker::Internet.uuid }
    let(:job) { described_class.new }
    let(:message) do
      {
        'host' => {
          'id' => Faker::Internet.uuid,
          'account' => Faker::Number.number(digits: 5).to_s,
          'org_id' => Faker::Number.number(digits: 6).to_s,
          'display_name' => Faker::Internet.domain_word,
          'groups' => [], 'tags' => [],
          'system_profile' => { 'operating_system' => { 'major' => 9, 'minor' => 4 }, 'owner_id' => owner_id },
          'stale_timestamp' => updated_time, 'created' => 1.day.ago.iso8601, 'updated' => updated_time,
          'insights_id' => Faker::Internet.uuid
        }
      }
    end

    before { job.instance_variable_set(:@message, message) }

    it 'upserts native system fields' do
      expect(Rails.logger).to receive(:audit_success).with(/Imported system/)

      expect { job.send(:import_system) }.to change(System, :count).by(1)

      system = System.find(message['host']['id'])
      expect(system.attributes.slice('owner_id', 'os_major_version', 'os_minor_version')).to eq(
        'owner_id' => owner_id, 'os_major_version' => 9, 'os_minor_version' => 4
      )
    end

    it 'does not include the removed column in the upsert' do
      allow(System).to receive(:upsert).and_call_original

      job.send(:import_system)

      expect(System).to have_received(:upsert) do |attributes, options|
        sql = options.fetch(:on_duplicate).to_s
        expect(attributes.keys).not_to include(:system_profile)
        expect(sql).not_to include('system_profile')
        expect(sql).to include('owner_id = EXCLUDED.owner_id')
        expect(sql).to include('os_major_version = EXCLUDED.os_major_version')
        expect(sql).to include('os_minor_version = EXCLUDED.os_minor_version')
        expect(sql).to include('WHERE COALESCE(systems.deleted_at, systems.updated) < EXCLUDED.updated')
      end
    end

    it 'ignores invalid tags and increments the invalid counter' do
      message['host']['tags'] = [Faker::Lorem.word]

      expect do
        expect(job.send(:import_system)).to be(false)
      end.to increment_yabeda_counter(Yabeda.compliance_system_import_invalid_total).by(1)
    end

    it 'does not overwrite a newer system' do
      FactoryBot.create(:system, id: message['host']['id'], updated: 1.day.from_now,
                                 os_major_version: 8, os_minor_version: 1)
      expect(Rails.logger).to receive(:info).with(/Ignored stale message/)

      job.send(:import_system)

      attributes = System.unscoped.find(message['host']['id']).attributes
      expect(attributes.slice('os_major_version', 'os_minor_version')).to eq(
        'os_major_version' => 8, 'os_minor_version' => 1
      )
    end

    it 'resurrects a soft-deleted system when the event is newer' do
      FactoryBot.create(:system, id: message['host']['id'], updated: 2.hours.ago, deleted_at: 1.hour.ago)

      job.send(:import_system)

      expect(System.find(message['host']['id']).deleted_at).to be_nil
    end

    it 'keeps a soft-deleted system deleted when the event is older' do
      FactoryBot.create(:system, id: message['host']['id'], updated: 2.hours.ago, deleted_at: 1.hour.from_now)

      job.send(:import_system)

      expect(System.unscoped.find(message['host']['id']).deleted_at).not_to be_nil
    end

    it 'logs malformed owner IDs and stores nil' do
      message['host']['system_profile']['owner_id'] = Faker::Lorem.word
      expect(Rails.logger).to receive(:error).with('[SystemImportJob] Malformed owner_id')

      job.send(:import_system)

      expect(System.find(message['host']['id']).owner_id).to be_nil
    end

    it 'ignores payloads missing a host ID' do
      message['host'].delete('id')
      expect(Rails.logger).to receive(:error).with(/Ignored invalid message/)

      expect { expect(job.send(:import_system)).to be(false) }.not_to change(System, :count)
    end

    it 're-raises malformed non-Hash hosts' do
      message['host'] = Faker::Lorem.word
      expect(Rails.logger).not_to receive(:audit_fail)

      expect { job.send(:import_system) }.to raise_error(NoMethodError)
    end

    context 'when the database raises an error' do
      before { allow(System).to receive(:upsert).and_raise(ActiveRecord::ActiveRecordError, 'db down') }

      it 'logs and re-raises the error' do
        expect(Rails.logger).to receive(:audit_fail).with(/Failed to import system.*db down/)

        expect { job.send(:import_system) }.to raise_error(ActiveRecord::ActiveRecordError, 'db down')
      end

      it 'does not count an intermediate failure' do
        expect do
          job.send(:import_system)
        rescue ActiveRecord::ActiveRecordError
          nil
        end.not_to increment_yabeda_counter(Yabeda.compliance_system_import_failures_total)
      end
    end

    it 'counts a terminal database failure' do
      allow(job).to receive(:terminal_import_attempt?).and_return(true)
      allow(System).to receive(:upsert).and_raise(ActiveRecord::ActiveRecordError)

      expect do
        job.send(:import_system)
      rescue ActiveRecord::ActiveRecordError
        nil
      end.to increment_yabeda_counter(Yabeda.compliance_system_import_failures_total).by(1)
    end

    it 'does not count a non-database failure' do
      allow(job).to receive(:extract_system_attrs).and_raise(StandardError, 'unexpected')
      expect(Rails.logger).to receive(:audit_fail).with(/Failed to import system.*unexpected/)

      expect do
        job.send(:import_system)
      rescue StandardError
        nil
      end.not_to increment_yabeda_counter(Yabeda.compliance_system_import_failures_total)
    end
  end

  describe '#import_policy_system' do
    let(:job) { described_class.new }
    let(:user) { FactoryBot.create(:user) }
    let(:policy_id) { FactoryBot.create(:policy, os_major_version: 8, supports_minors: [0], empty_policy: true).id }
    let(:system_id) { FactoryBot.create(:system, account: user.account).id }
    let(:message) do
      {
        'type' => 'created',
        'host' => {
          'id' => system_id, 'org_id' => user.org_id,
          'system_profile' => { 'image_builder' => { 'compliance_policy_id' => policy_id } }
        }
      }
    end

    before do
      job.instance_variable_set(:@message, message)
      allow(SupportedSsg).to receive(:all).and_return(
        [
          SupportedSsg.new(os_major_version: '8', os_minor_version: '0', version: '0.1.72'),
          SupportedSsg.new(os_major_version: '8', os_minor_version: '1', version: '0.1.73')
        ]
      )
    end

    it 'creates a policy association' do
      expect(Rails.logger).to receive(:audit_success).with(
        "[#{user.org_id}] Imported PolicySystem for System #{system_id} from created message"
      )

      expect { job.send(:import_policy_system) }.to change(PolicySystem, :count).by(1)
    end

    it 'raises when the system does not exist' do
      message['host']['id'] = Faker::Internet.uuid
      expect(Rails.logger).to receive(:audit_fail).with(
        "[#{user.org_id}] Failed to import PolicySystem: System not found with ID #{message['host']['id']}"
      )

      expect { job.send(:import_policy_system) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(PolicySystem.count).to eq(0)
    end

    it 'does not create an association for a missing policy' do
      message['host']['system_profile']['image_builder']['compliance_policy_id'] = Faker::Internet.uuid
      expect(Rails.logger).to receive(:audit_fail).with(
        "[#{user.org_id}] Failed to import PolicySystem: Policy not found with ID " \
        "#{message.dig('host', 'system_profile', 'image_builder', 'compliance_policy_id')}"
      )

      expect { job.send(:import_policy_system) }.not_to change(PolicySystem, :count)
    end

    it 'does not create an association for an incompatible policy' do
      message['host']['system_profile']['image_builder']['compliance_policy_id'] =
        FactoryBot.create(:policy, os_major_version: 7, supports_minors: [0], empty_policy: true).id
      expect(Rails.logger).to receive(:audit_fail).with(
        "[#{user.org_id}] Failed to import PolicySystem: System Unsupported OS major version"
      )

      expect { job.send(:import_policy_system) }.not_to change(PolicySystem, :count)
    end

    it 'does not duplicate an existing policy association' do
      FactoryBot.create(:policy_system, policy_id: policy_id, system_id: system_id)
      expect(Rails.logger).to receive(:audit_fail).with(
        a_string_including("[#{user.org_id}] Failed to import PolicySystem: System has already been taken")
      )

      expect { job.send(:import_policy_system) }.not_to change(PolicySystem, :count)
    end
  end
end

RSpec.describe SystemImportJob, 'database idempotency' do
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

    described_class.perform_now(message)
    described_class.perform_now(message)

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

    described_class.perform_now(newer_message)
    described_class.perform_now(older_message)

    expect(System.find(system_id).display_name).to eq('newer-system')
  end
end
