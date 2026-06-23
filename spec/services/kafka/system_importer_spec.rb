# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kafka::SystemImporter do
  let(:logger) { instance_double('Logger', info: true, error: true) }
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
        'stale_timestamp' => Time.now.utc.iso8601,
        'created' => (Time.now.utc - 1.day).iso8601,
        'updated' => Time.now.utc.iso8601,
        'insights_id' => SecureRandom.uuid
      }
    }
  end

  subject { described_class.new(message, logger) }

  describe '#import' do
    context 'when payload is invalid (missing id)' do
      before { message['host'].delete('id') }

      it 'ignores the message and logs an error' do
        expect { subject.import }.not_to(change { KafkaSystem.count })
        expect(logger).to have_received(:error).with(/\[Kafka::SystemImporter\] Ignored invalid message/)
      end
    end

    context 'when payload is invalid (malformed tags)' do
      before { message['host']['tags'] = ['string_tag_not_hash'] }

      it 'ignores the message and logs an error' do
        expect { subject.import }.not_to(change { KafkaSystem.count })
        expect(logger).to have_received(:error).with(/\[Kafka::SystemImporter\] Ignored invalid message/)
      end
    end

    context 'when system is new' do
      it 'upserts system' do
        expect { subject.import }.to change { KafkaSystem.count }.by(1)
        expect(logger).to have_received(:info).with(/\[Kafka::SystemImporter\] Imported system/)
      end
    end

    context 'when message is an update to an existing system' do
      let!(:existing_system) do
        system = FactoryBot.create(
          :kafka_system,
          id: message['host']['id'],
          display_name: 'old-name'
        )
        system.update!(updated: (Time.now.utc - 2.days).iso8601)
        system
      end

      it 'updates the existing system attributes' do
        expect { subject.import }.not_to(change { KafkaSystem.count })

        system = KafkaSystem.find(message['host']['id'])
        expect(system.display_name).to eq(message.dig('host', 'display_name'))
        expect(logger).to have_received(:info).with(/\[Kafka::SystemImporter\] Imported system/)
      end
    end

    context 'when message is exactly the same age (repeated message)' do
      let!(:existing_system) do
        system = FactoryBot.create(
          :kafka_system,
          id: message['host']['id'],
          display_name: 'old-name'
        )
        system.update!(updated: message['host']['updated'])
        system
      end

      it 'ignores the repeated message' do
        expect { subject.import }.not_to(change { KafkaSystem.count })

        system = KafkaSystem.find(message['host']['id'])
        expect(system.display_name).to eq('old-name') # prove it was not updated
        expect(logger).to have_received(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
      end
    end

    context 'when message is strictly stale (older than DB)' do
      before do
        system = FactoryBot.create(
          :kafka_system,
          id: message['host']['id']
        )
        system.update!(updated: (Time.now.utc + 1.day).iso8601)
      end

      it 'ignores the stale message' do
        expect { subject.import }.not_to(change { KafkaSystem.count })
        expect(logger).to have_received(:info).with(/\[Kafka::SystemImporter\] Ignored stale message/)
      end
    end

    context 'when payload lacks optional fields like groups' do
      before { message['host'].delete('groups') }

      it 'upserts using fallback defaults' do
        subject.import
        system = KafkaSystem.find(message['host']['id'])
        expect(system.groups).to eq([])
      end
    end

    context 'when exception occurs' do
      before do
        allow(KafkaSystem).to receive(:upsert).and_raise(ActiveRecord::ActiveRecordError, 'db down')
      end

      it 'logs error and re-raises it' do
        expect { subject.import }.to raise_error(ActiveRecord::ActiveRecordError, 'db down')
        expect(logger).to have_received(:error).with(/\[Kafka::SystemImporter\] Failed to import system.*db down/)
      end
    end

    context 'when payload is entirely empty' do
      let(:message) { {} }

      it 'ignores the message and logs an error' do
        expect { subject.import }.not_to(change { KafkaSystem.count })
        expect(logger).to have_received(:error).with(/\[Kafka::SystemImporter\] Ignored invalid message/)
      end
    end

    context 'when payload is flat (no host key)' do
      let(:message) do
        {
          'id' => SecureRandom.uuid,
          'account' => Faker::Number.number(digits: 5).to_s,
          'org_id' => Faker::Number.number(digits: 6).to_s,
          'display_name' => Faker::Internet.domain_word,
          'tags' => [],
          'system_profile' => {},
          'stale_timestamp' => Time.now.utc.iso8601,
          'created' => (Time.now.utc - 1.day).iso8601,
          'updated' => Time.now.utc.iso8601
        }
      end

      it 'upserts the system correctly by falling back to root message' do
        expect { subject.import }.to change { KafkaSystem.count }.by(1)
        system = KafkaSystem.find(message['id'])
        expect(system.account).to eq(message['account'])
        expect(system.groups).to eq([])
      end
    end

    # Empty context removed

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
            'stale_timestamp' => Time.now.utc.iso8601,
            'created' => (Time.now.utc - 1.day).iso8601,
            'updated' => nil,
            'insights_id' => SecureRandom.uuid
          }
        }
      end

      it 'catches DB validation error during upsert due to NOT NULL constraint' do
        expect { subject.import }.to raise_error(ActiveRecord::NotNullViolation)
        expect(logger).to have_received(:error).with(/\[Kafka::SystemImporter\] Failed to import system/)
      end
    end
  end
end
