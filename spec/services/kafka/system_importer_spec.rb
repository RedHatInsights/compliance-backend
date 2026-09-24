# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Kafka::SystemImporter do
  let(:updated_time) { Time.current.iso8601 }
  let(:owner_id) { Faker::Internet.uuid }
  let(:message) do
    {
      'host' => {
        'id' => Faker::Internet.uuid,
        'account' => Faker::Number.number(digits: 5).to_s,
        'org_id' => Faker::Number.number(digits: 6).to_s,
        'display_name' => Faker::Internet.domain_word,
        'groups' => [],
        'tags' => [],
        'system_profile' => {
          'operating_system' => { 'major' => 9, 'minor' => 4 },
          'owner_id' => owner_id
        },
        'stale_timestamp' => updated_time,
        'created' => 1.day.ago.iso8601,
        'updated' => updated_time,
        'insights_id' => Faker::Internet.uuid
      }
    }
  end
  let(:terminal_attempt) { false }
  let(:service) { described_class.new(message, Karafka.logger, terminal_attempt: terminal_attempt) }

  describe '#import' do
    it 'upserts native fields from the Kafka payload' do
      expect(Karafka.logger).to receive(:audit_success).with(/Imported system/)

      expect { service.import }.to change(System, :count).by(1)

      system = System.find(message['host']['id'])
      expect(system.owner_id).to eq(owner_id)
      expect(system.os_major_version).to eq(9)
      expect(system.os_minor_version).to eq(4)
    end

    it 'does not include the removed column in the upsert' do
      allow(System).to receive(:upsert).and_call_original

      service.import

      expect(System).to have_received(:upsert) do |attributes, options|
        sql = options.fetch(:on_duplicate).to_s
        expect(attributes.keys).not_to include(:system_profile)
        expect(sql).not_to include('system_profile')
        expect(sql).to include('owner_id = EXCLUDED.owner_id')
        expect(sql).to include('os_major_version = EXCLUDED.os_major_version')
        expect(sql).to include('os_minor_version = EXCLUDED.os_minor_version')
      end
    end

    context 'when owner_id is malformed' do
      before { message['host']['system_profile']['owner_id'] = Faker::Lorem.word }

      it 'logs the malformed value and stores a null native owner' do
        expect(Karafka.logger).to receive(:error).with('[Kafka::SystemImporter] Malformed owner_id')

        service.import

        expect(System.find(message['host']['id']).owner_id).to be_nil
      end
    end

    context 'when the message is stale' do
      before do
        FactoryBot.create(
          :system,
          id: message['host']['id'],
          updated: 1.day.from_now,
          owner_id: Faker::Internet.uuid,
          os_major_version: 8,
          os_minor_version: 1
        )
      end

      it 'does not change the existing native values' do
        expect(Karafka.logger).to receive(:info).with(/Ignored stale message/)

        service.import

        system = System.unscoped.find(message['host']['id'])
        expect(system.os_major_version).to eq(8)
        expect(system.os_minor_version).to eq(1)
      end
    end

    context 'when the payload is invalid' do
      before { message['host'].delete('id') }

      it 'ignores the message' do
        expect(Karafka.logger).to receive(:error).with(/Ignored invalid message/)
        expect { service.import }.not_to change(System, :count)
      end
    end

    context 'when the database raises an error' do
      before { allow(System).to receive(:upsert).and_raise(ActiveRecord::ActiveRecordError, 'db down') }

      it 'logs and re-raises the error' do
        expect(Karafka.logger).to receive(:audit_fail).with(/Failed to import system.*db down/)
        expect { service.import }.to raise_error(ActiveRecord::ActiveRecordError, 'db down')
      end
    end
  end
end
