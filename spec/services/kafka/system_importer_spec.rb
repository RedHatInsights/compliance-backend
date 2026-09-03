# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kafka::SystemImporter do
  let(:updated_time) { Time.now.utc.iso8601 }
  let(:message) do
    {
      'host' => {
        'id' => SecureRandom.uuid,
        'account' => Faker::Number.number(digits: 5).to_s,
        'org_id' => Faker::Number.number(digits: 6).to_s,
        'display_name' => Faker::Internet.domain_word,
        'groups' => [],
        'tags' => [],
        'system_profile' => {
          'operating_system' => { 'major' => 9, 'minor' => 4 },
          'owner_id' => SecureRandom.uuid
        },
        'stale_timestamp' => updated_time,
        'created' => (Time.now.utc - 1.day).iso8601,
        'updated' => updated_time,
        'insights_id' => SecureRandom.uuid
      }
    }
  end

  let(:service) { described_class.new(message, Karafka.logger) }

  describe '#import' do
    # rubocop:disable Rails/SkipsModelValidations
    shared_context 'with an existing owned system' do
      let(:existing_owner_id) { SecureRandom.uuid }
      let!(:existing_system) do
        system = FactoryBot.create(
          :system,
          id: message['host']['id'],
          updated: (Time.zone.parse(updated_time) - 2.days).iso8601,
          system_profile: { 'owner_id' => existing_owner_id }
        )
        system.update_columns(owner_id: existing_owner_id)
        system
      end
    end

    shared_context 'with existing native OS versions' do
      let!(:existing_system) do
        system = FactoryBot.create(
          :system,
          id: message['host']['id'],
          updated: (Time.zone.parse(updated_time) - 2.days).iso8601,
          system_profile: { 'operating_system' => { 'major' => 8, 'minor' => 0 } }
        )
        system.update_columns(os_major_version: 8, os_minor_version: 0)
        system
      end
    end

    context 'when payload is invalid (missing id)' do
      before { message['host'].delete('id') }

      it 'ignores the message and logs an error' do
        expect(Karafka.logger).to receive(:error).with(/\[Kafka::SystemImporter\] Ignored invalid message/)
        expect { service.import }.not_to(change { System.count })
      end

      it 'increments the invalid counter' do
        expect { service.import }.to increment_yabeda_counter(Yabeda.compliance_system_import_invalid_total).by(1)
      end
    end

    context 'when payload is invalid (malformed tags)' do
      before { message['host']['tags'] = ['string_tag_not_hash'] }

      it 'ignores the message and logs an error' do
        expect(Karafka.logger).to receive(:error).with(/\[Kafka::SystemImporter\] Ignored invalid message/)
        expect { service.import }.not_to(change { System.count })
      end

      it 'increments the invalid counter' do
        expect { service.import }.to increment_yabeda_counter(Yabeda.compliance_system_import_invalid_total).by(1)
      end
    end

    context 'when system is new' do
      it 'upserts the JSONB profile and native fields' do
        expect(Karafka.logger).to receive(:audit_success).with(/\[Kafka::SystemImporter\] Imported system/)
        expect { service.import }.to change { System.count }.by(1)

        system = System.find(message['host']['id'])
        expect(system.system_profile).to eq(message.dig('host', 'system_profile'))
        expect(system[:os_major_version]).to eq(9)
        expect(system[:os_minor_version]).to eq(4)
        expect(system[:owner_id]).to eq(message.dig('host', 'system_profile', 'owner_id'))
      end
    end

    context 'when message is an update to an existing system' do
      let!(:existing_system) do
        system = FactoryBot.create(
          :system,
          id: message['host']['id'],
          display_name: Faker::Internet.domain_word,
          updated: (Time.zone.parse(updated_time) - 2.days).iso8601,
          system_profile: {
            'operating_system' => { 'major' => 8, 'minor' => 0 },
            'owner_id' => SecureRandom.uuid
          }
        )
        system.update_columns(
          os_major_version: 8,
          os_minor_version: 0,
          owner_id: SecureRandom.uuid
        )
        system
      end

      it 'updates the JSONB profile and native fields' do
        expect(Karafka.logger).to receive(:audit_success).with(/\[Kafka::SystemImporter\] Imported system/)
        expect { service.import }.not_to(change { System.count })

        system = System.find(message['host']['id'])
        expect(system.display_name).to eq(message.dig('host', 'display_name'))
        expect(system.system_profile).to eq(message.dig('host', 'system_profile'))
        expect(system[:os_major_version]).to eq(9)
        expect(system[:os_minor_version]).to eq(4)
        expect(system[:owner_id]).to eq(message.dig('host', 'system_profile', 'owner_id'))
      end
    end

    context 'when a newer message omits owner_id' do
      include_context 'with an existing owned system'

      before { message['host']['system_profile'].delete('owner_id') }

      it 'removes owner_id from JSONB and clears the native column' do
        service.import
        system = System.find(message['host']['id'])
        expect(system.system_profile).not_to have_key('owner_id')
        expect(system[:owner_id]).to be_nil
      end
    end

    context 'when a newer message has a null owner_id' do
      include_context 'with an existing owned system'

      before { message['host']['system_profile']['owner_id'] = nil }

      it 'retains JSON null and clears the native column' do
        service.import
        system = System.find(message['host']['id'])
        expect(system.system_profile).to have_key('owner_id')
        expect(system.system_profile['owner_id']).to be_nil
        expect(system[:owner_id]).to be_nil
      end
    end

    context 'when owner_id is a malformed UUID string' do
      before { message['host']['system_profile']['owner_id'] = Faker::Lorem.word }

      it 'logs an error and imports JSONB with a null native owner' do
        expect(Karafka.logger)
          .to receive(:error)
          .with(/\[Kafka::SystemImporter\] Malformed owner_id/)

        expect { service.import }.to change { System.count }.by(1)
        system = System.find(message['host']['id'])
        expect(system.system_profile['owner_id']).to eq(message.dig('host', 'system_profile', 'owner_id'))
        expect(system[:owner_id]).to be_nil
      end
    end

    context 'when owner_id is not a string' do
      before { message['host']['system_profile']['owner_id'] = 1 }

      it 'logs an error and imports JSONB with a null native owner' do
        expect(Karafka.logger)
          .to receive(:error)
          .with(/\[Kafka::SystemImporter\] Malformed owner_id/)

        expect { service.import }.to change { System.count }.by(1)
        system = System.find(message['host']['id'])
        expect(system.system_profile['owner_id']).to eq(1)
        expect(system[:owner_id]).to be_nil
      end
    end

    context 'when a newer message omits operating_system' do
      include_context 'with existing native OS versions'

      before { message['host']['system_profile'].delete('operating_system') }

      it 'removes operating_system from JSONB and clears native OS versions' do
        service.import
        system = System.find(message['host']['id'])
        expect(system.system_profile).not_to have_key('operating_system')
        expect(system[:os_major_version]).to be_nil
        expect(system[:os_minor_version]).to be_nil
      end
    end

    context 'when a newer message has a non-hash operating_system' do
      include_context 'with existing native OS versions'

      before { message['host']['system_profile']['operating_system'] = Faker::Lorem.word }

      it 'retains the JSONB value and clears native OS versions' do
        service.import
        system = System.find(message['host']['id'])
        expect(system.system_profile['operating_system'])
          .to eq(message.dig('host', 'system_profile', 'operating_system'))
        expect(system[:os_major_version]).to be_nil
        expect(system[:os_minor_version]).to be_nil
      end
    end

    context 'when message is exactly the same age (repeated message)' do
      let!(:existing_system) do
        FactoryBot.create(
          :system,
          id: message['host']['id'],
          display_name: 'old-name',
          updated: updated_time
        )
      end

      it 'ignores the repeated message' do
        expect(Karafka.logger).to receive(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
        expect { service.import }.not_to(change { System.count })

        system = System.find(message['host']['id'])
        expect(system.display_name).to eq('old-name')
      end

      it 'increments the stale counter' do
        expect { service.import }.to increment_yabeda_counter(Yabeda.compliance_system_import_stale_total).by(1)
      end
    end

    context 'when message is strictly stale (older than DB)' do
      let(:existing_owner_id) { SecureRandom.uuid }
      let!(:existing_system) do
        system = FactoryBot.create(
          :system,
          id: message['host']['id'],
          updated: (Time.zone.parse(updated_time) + 1.day).iso8601,
          system_profile: {
            'operating_system' => { 'major' => 8, 'minor' => 0 },
            'owner_id' => existing_owner_id
          }
        )
        system.update_columns(
          os_major_version: 8,
          os_minor_version: 0,
          owner_id: existing_owner_id
        )
        system
      end

      it 'ignores the stale message' do
        expect(Karafka.logger).to receive(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
        expect { service.import }.not_to(change { System.count })
      end

      it 'increments the stale counter' do
        expect { service.import }.to increment_yabeda_counter(Yabeda.compliance_system_import_stale_total).by(1)
      end

      it 'preserves the JSONB profile and native fields' do
        service.import
        system = System.find(message['host']['id'])
        expect(system.system_profile).to eq(existing_system.system_profile)
        expect(system[:os_major_version]).to eq(8)
        expect(system[:os_minor_version]).to eq(0)
        expect(system[:owner_id]).to eq(existing_owner_id)
      end
    end
    # rubocop:enable Rails/SkipsModelValidations

    context 'when existing system is soft-deleted (has deleted_at set)' do
      let(:system_id) { message['host']['id'] }

      context 'and incoming message has a newer updated timestamp' do
        before do
          FactoryBot.create(
            :system,
            id: system_id,
            display_name: 'old-name',
            updated: (Time.zone.parse(updated_time) - 2.hours).iso8601,
            deleted_at: (Time.zone.parse(updated_time) - 1.hour).iso8601
          )
        end

        it 'resurrects the system by setting deleted_at to nil' do
          expect(Karafka.logger).to receive(:audit_success).with(/\[Kafka::SystemImporter\] Imported system/)
          expect { service.import }.to change { System.count }.by(1)

          system = System.find(system_id)
          expect(system.deleted_at).to be_nil
          expect(system.display_name).to eq(message.dig('host', 'display_name'))
        end
      end

      context 'and incoming message has an older updated timestamp than deleted_at' do
        before do
          FactoryBot.create(
            :system,
            id: system_id,
            display_name: 'old-name',
            updated: (Time.zone.parse(updated_time) - 2.hours).iso8601,
            deleted_at: (Time.zone.parse(updated_time) + 1.hour).iso8601
          )
        end

        it 'ignores the message as stale' do
          expect(Karafka.logger).to receive(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
          expect { service.import }.not_to(change { System.count })

          system = System.unscoped.find(system_id)
          expect(system.deleted_at).not_to be_nil
          expect(system.display_name).to eq('old-name')
        end
      end
    end

    context 'when system_profile contains extra fields' do
      before do
        message['host']['system_profile'] = {
          'operating_system' => { 'major' => 9, 'minor' => 4 },
          'owner_id' => SecureRandom.uuid,
          'arch' => 'x86_64',
          'bios_vendor' => 'SeaBIOS',
          'cpu_model' => 'Intel Xeon',
          'network_interfaces' => [{ 'name' => 'eth0' }]
        }
      end

      it 'stores only operating_system and owner_id' do
        service.import
        system = System.find(message['host']['id'])
        expect(system.system_profile.keys).to match_array(%w[operating_system owner_id])
        expect(system.system_profile['operating_system']).to eq({ 'major' => 9, 'minor' => 4 })
      end
    end

    context 'when payload lacks optional fields like groups' do
      before { message['host'].delete('groups') }

      it 'upserts using fallback defaults' do
        service.import
        system = System.find(message['host']['id'])
        expect(system.groups).to eq([])
      end
    end

    context 'when a database exception occurs' do
      before do
        allow(System).to receive(:upsert).and_raise(ActiveRecord::ActiveRecordError, 'db down')
      end

      it 'logs error and re-raises it' do
        expect(Karafka.logger)
          .to receive(:audit_fail)
          .with(/\[Kafka::SystemImporter\] Failed to import system.*db down/)
        expect { service.import }.to raise_error(ActiveRecord::ActiveRecordError, 'db down')
      end

      it 'increments the failures counter' do
        expect do
          service.import
        rescue ActiveRecord::ActiveRecordError
          nil
        end.to increment_yabeda_counter(Yabeda.compliance_system_import_failures_total).by(1)
      end
    end

    context 'when a non-database exception occurs' do
      before do
        allow(service).to receive(:extract_system_attrs).and_raise(StandardError, 'unexpected')
      end

      it 'logs error and re-raises it' do
        expect(Karafka.logger)
          .to receive(:audit_fail)
          .with(/\[Kafka::SystemImporter\] Failed to import system.*unexpected/)
        expect { service.import }.to raise_error(StandardError, 'unexpected')
      end

      it 'does not increment the failures counter' do
        expect do
          service.import
        rescue StandardError
          nil
        end.not_to increment_yabeda_counter(Yabeda.compliance_system_import_failures_total)
      end
    end

    context 'when message has nil updated timestamp' do
      let(:message) do
        {
          'host' => {
            'id' => SecureRandom.uuid,
            'account' => '12345',
            'org_id' => 'org123',
            'display_name' => 'test-host',
            'groups' => [],
            'tags' => [],
            'system_profile' => {},
            'stale_timestamp' => updated_time,
            'created' => (Time.now.utc - 1.day).iso8601,
            'updated' => nil,
            'insights_id' => SecureRandom.uuid
          }
        }
      end

      it 'catches DB validation error during upsert due to NOT NULL constraint' do
        expect(Karafka.logger).to receive(:audit_fail).with(/\[Kafka::SystemImporter\] Failed to import system/)
        expect { service.import }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end
  end
end
