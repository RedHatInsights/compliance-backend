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
        'system_profile' => {},
        'stale_timestamp' => updated_time,
        'created' => (Time.now.utc - 1.day).iso8601,
        'updated' => updated_time,
        'insights_id' => SecureRandom.uuid
      }
    }
  end

  let(:service) { described_class.new(message, Karafka.logger) }

  describe '#import' do
    context 'when payload is invalid (missing id)' do
      before { message['host'].delete('id') }

      it 'ignores the message and logs an error' do
        expect(Karafka.logger).to receive(:error).with(/\[Kafka::SystemImporter\] Ignored invalid message/)
        expect { service.import }.not_to(change { KafkaSystem.count })
      end
    end

    context 'when payload is invalid (malformed tags)' do
      before { message['host']['tags'] = ['string_tag_not_hash'] }

      it 'ignores the message and logs an error' do
        expect(Karafka.logger).to receive(:error).with(/\[Kafka::SystemImporter\] Ignored invalid message/)
        expect { service.import }.not_to(change { KafkaSystem.count })
      end
    end

    context 'when system is new' do
      it 'upserts system' do
        expect(Karafka.logger).to receive(:audit_success).with(/\[Kafka::SystemImporter\] Imported system/)
        expect { service.import }.to change { KafkaSystem.count }.by(1)
      end
    end

    context 'when message is an update to an existing system' do
      let!(:existing_system) do
        FactoryBot.create(
          :kafka_system,
          id: message['host']['id'],
          display_name: 'old-name',
          updated: (Time.zone.parse(updated_time) - 2.days).iso8601
        )
      end

      it 'updates the existing system attributes' do
        expect(Karafka.logger).to receive(:audit_success).with(/\[Kafka::SystemImporter\] Imported system/)
        expect { service.import }.not_to(change { KafkaSystem.count })

        system = KafkaSystem.find(message['host']['id'])
        expect(system.display_name).to eq(message.dig('host', 'display_name'))
      end
    end

    context 'when message is exactly the same age (repeated message)' do
      let!(:existing_system) do
        FactoryBot.create(
          :kafka_system,
          id: message['host']['id'],
          display_name: 'old-name',
          updated: updated_time
        )
      end

      it 'ignores the repeated message' do
        expect(Karafka.logger).to receive(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
        expect { service.import }.not_to(change { KafkaSystem.count })

        system = KafkaSystem.find(message['host']['id'])
        expect(system.display_name).to eq('old-name')
      end
    end

    context 'when message is strictly stale (older than DB)' do
      before do
        FactoryBot.create(
          :kafka_system,
          id: message['host']['id'],
          updated: (Time.zone.parse(updated_time) + 1.day).iso8601
        )
      end

      it 'ignores the stale message' do
        expect(Karafka.logger).to receive(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
        expect { service.import }.not_to(change { KafkaSystem.count })
      end
    end

    context 'when system is deleted and new create message arrives' do
      let!(:existing_system) do
        FactoryBot.create(
          :kafka_system,
          id: message['host']['id'],
          updated: (Time.zone.parse(updated_time) - 2.days).iso8601,
          deleted_at: (Time.zone.parse(updated_time) - 1.day).iso8601
        )
      end

      it 'recreates the system and clears deleted_at' do
        expect(Karafka.logger).to receive(:audit_success).with(/\[Kafka::SystemImporter\] Imported system/)
        expect { service.import }.not_to(change { KafkaSystem.unscoped.count })

        system = KafkaSystem.find(message['host']['id'])
        expect(system.deleted_at).to be_nil
        expect(system.display_name).to eq(message.dig('host', 'display_name'))
      end
    end

    context 'when system is deleted and update message is older' do
      let!(:existing_system) do
        FactoryBot.create(
          :kafka_system,
          id: message['host']['id'],
          updated: (Time.zone.parse(updated_time) - 2.days).iso8601,
          deleted_at: (Time.zone.parse(updated_time) + 1.day).iso8601
        )
      end

      it 'ignores the update and leaves system deleted' do
        expect(Karafka.logger).to receive(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
        expect { service.import }.not_to(change { KafkaSystem.unscoped.count })

        system = KafkaSystem.unscoped.find(message['host']['id'])
        expect(system.deleted_at).not_to be_nil
        expect(system.display_name).to eq(existing_system.display_name)
      end
    end

    context 'when payload lacks optional fields like groups' do
      before { message['host'].delete('groups') }

      it 'upserts using fallback defaults' do
        service.import
        system = KafkaSystem.find(message['host']['id'])
        expect(system.groups).to eq([])
      end
    end

    context 'when exception occurs' do
      before do
        allow(KafkaSystem).to receive(:upsert).and_raise(ActiveRecord::ActiveRecordError, 'db down')
      end

      it 'logs error and re-raises it' do
        expect(Karafka.logger)
          .to receive(:audit_fail)
          .with(/\[Kafka::SystemImporter\] Failed to import system.*db down/)
        expect { service.import }.to raise_error(ActiveRecord::ActiveRecordError, 'db down')
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
