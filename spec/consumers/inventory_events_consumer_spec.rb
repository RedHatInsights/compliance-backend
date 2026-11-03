# frozen_string_literal: true

require 'rails_helper'

describe InventoryEventsConsumer do
  subject(:consumer) { karafka.consumer_for(Settings.kafka.topics.inventory_events) }

  before do
    karafka.produce(message.to_json)
  end

  let(:message) do
    {
      'type' => type,
      'host' => {
        'id' => SecureRandom.uuid,
        'insights_id' => SecureRandom.uuid
      }
    }
  end

  let(:import_payload) do
    {
      'type' => type,
      'host' => message.fetch('host').slice('id', 'insights_id')
    }
  end

  describe 'handling messages with unknown type' do
    let(:type) { 'somethingelse' }

    it 'logs a debug message and skips processing' do
      expect(Karafka.logger).to receive(:debug).with("Skipped message of type '#{type}'")
      expect(SystemImportJob).not_to receive(:perform_later)
      expect(SystemDeleteJob).not_to receive(:perform_later)
      expect(Kafka::ReportParser).not_to receive(:new)

      consumer.consume
    end
  end

  describe 'handling messages by type' do
    context 'when message is delete' do
      let(:type) { 'delete' }
      let(:message) do
        {
          'type' => type,
          'id' => SecureRandom.uuid,
          'org_id' => Faker::Number.number(digits: 6).to_s,
          'updated' => Time.current.iso8601
        }
      end

      it 'enqueues SystemDeleteJob with the required delete fields' do
        delete_payload = message.slice('id', 'org_id', 'updated', 'timestamp')
        expect(SystemDeleteJob).to receive(:perform_later).with(delete_payload)

        consumer.consume
      end

      context 'with a rich payload' do
        let(:message) do
          {
            'type' => type,
            'id' => SecureRandom.uuid,
            'org_id' => Faker::Number.number(digits: 6).to_s,
            'updated' => 2.minutes.ago.iso8601,
            'timestamp' => 1.minute.ago.iso8601,
            'unrelated' => Faker::Lorem.sentence,
            'host' => { 'id' => SecureRandom.uuid, 'unrelated' => Faker::Lorem.sentence },
            'platform_metadata' => { 'service' => 'inventory', 'unrelated' => Faker::Lorem.sentence }
          }
        end

        it 'projects delete fields' do
          delete_payload = message.slice('id', 'org_id', 'updated', 'timestamp')
          expect(SystemDeleteJob).to receive(:perform_later).with(delete_payload)

          consumer.consume
        end
      end

      context 'when updated is absent' do
        let(:message) do
          {
            'type' => type,
            'id' => SecureRandom.uuid,
            'org_id' => Faker::Number.number(digits: 6).to_s,
            'timestamp' => Time.current.iso8601,
            'unrelated' => Faker::Lorem.sentence
          }
        end

        it 'preserves the timestamp fallback and omits unrelated fields' do
          delete_payload = message.slice('id', 'org_id', 'updated', 'timestamp')
          expect(SystemDeleteJob).to receive(:perform_later).with(delete_payload)

          consumer.consume
        end
      end

      it 'propagates enqueue failures' do
        allow(SystemDeleteJob).to receive(:perform_later).and_raise(StandardError, 'enqueue failed')

        expect { consumer.consume }.to raise_error(StandardError, 'enqueue failed')
      end
    end

    context 'when message is created or updated' do
      %w[created updated].each do |msg_type|
        context "with #{msg_type} message" do
          let(:type) { msg_type }

          it 'enqueues SystemImportJob' do
            expect(SystemImportJob).to receive(:perform_later).with(import_payload)

            consumer.consume
          end

          it 'parses the payload once' do
            expect(JSON).to receive(:parse).once.and_call_original
            expect(SystemImportJob).to receive(:perform_later)

            consumer.consume
          end

          it 'parses each Kafka payload once' do
            second_message = message.deep_merge(
              'host' => { 'id' => SecureRandom.uuid, 'insights_id' => SecureRandom.uuid }
            )
            karafka.produce(second_message.to_json)
            expect(JSON).to receive(:parse).twice.and_call_original
            expect(SystemImportJob).to receive(:perform_later).twice

            consumer.consume
          end

          context 'with a rich payload' do
            let(:org_id) { Faker::Number.number(digits: 6).to_s }
            let(:system_id) { SecureRandom.uuid }
            let(:host_name) { Faker::Internet.domain_name }
            let(:policy_id) { SecureRandom.uuid }
            let(:request_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
            let(:identity) { Base64.strict_encode64(Faker::Internet.email) }
            let(:metadata_url) { Faker::Internet.url }
            let(:discarded) { Faker::Lorem.sentence }

            let(:message) do
              {
                'type' => type,
                'id' => system_id,
                'unrelated' => discarded,
                'host' => {
                  'id' => system_id,
                  'insights_id' => SecureRandom.uuid,
                  'account' => org_id,
                  'org_id' => org_id,
                  'display_name' => host_name,
                  'groups' => [Faker::Lorem.word],
                  'tags' => [{ 'namespace' => 'insights', 'key' => 'env', 'value' => 'test' }],
                  'stale_timestamp' => '2026-10-14T10:00:00Z',
                  'created' => '2026-10-13T10:00:00Z',
                  'updated' => '2026-10-14T10:00:00Z',
                  'system_profile' => {
                    'owner_id' => SecureRandom.uuid,
                    'operating_system' => {
                      'major' => '9',
                      'minor' => '4',
                      'name' => 'Red Hat Enterprise Linux',
                      'unrelated' => discarded
                    },
                    'image_builder' => {
                      'compliance_policy_id' => policy_id,
                      'unrelated' => discarded
                    },
                    'unrelated' => discarded
                  },
                  'unrelated' => discarded
                },
                'platform_metadata' => {
                  'service' => 'compliance',
                  'request_id' => request_id,
                  'org_id' => org_id,
                  'b64_identity' => identity,
                  'url' => metadata_url,
                  'metadata' => { 'full' => { 'nested' => Faker::Lorem.sentence } },
                  'unrelated' => discarded
                }
              }
            end

            let(:import_payload) do
              {
                'type' => type,
                'id' => message['id'],
                'host' => message['host'].slice(
                  'id', 'insights_id', 'account', 'org_id', 'display_name', 'groups', 'tags',
                  'stale_timestamp', 'created', 'updated'
                ).merge(
                  'system_profile' => {
                    'owner_id' => message.dig('host', 'system_profile', 'owner_id'),
                    'operating_system' => {
                      'major' => '9',
                      'minor' => '4'
                    },
                    'image_builder' => { 'compliance_policy_id' => policy_id }
                  }
                ),
                'platform_metadata' => {
                  'service' => 'compliance',
                  'request_id' => request_id,
                  'org_id' => org_id,
                  'b64_identity' => identity,
                  'url' => metadata_url,
                  'metadata' => message.dig('platform_metadata', 'metadata')
                }
              }
            end

            it 'projects import fields and passes through parser metadata' do
              expect(SystemImportJob).to receive(:perform_later).with(import_payload)

              consumer.consume
            end
          end

          context 'when the host is not importable' do
            let(:message) { super().deep_merge('host' => excluded_host) }

            shared_examples 'skips the job' do
              it 'does not enqueue SystemImportJob' do
                expect(SystemImportJob).not_to receive(:perform_later)

                consumer.consume
              end
            end

            context 'without an Insights ID' do
              let(:message) do
                {
                  'type' => type,
                  'host' => { 'id' => SecureRandom.uuid }
                }
              end

              include_examples 'skips the job'
            end

            context 'with the non-Insights ID' do
              let(:message) do
                {
                  'type' => type,
                  'host' => {
                    'id' => SecureRandom.uuid,
                    'insights_id' => described_class::NON_INSIGHTS_ID
                  }
                }
              end

              include_examples 'skips the job'
            end

            context 'when it is an edge host' do
              let(:excluded_host) { { 'system_profile' => { 'host_type' => 'edge' } } }

              include_examples 'skips the job'
            end

            context 'when it runs CentOS' do
              let(:excluded_host) do
                { 'system_profile' => { 'operating_system' => { 'name' => 'CentOS Linux' } } }
              end

              include_examples 'skips the job'
            end

            context 'when it is booted from a bootc image' do
              let(:excluded_host) do
                {
                  'system_profile' => {
                    'bootc_status' => { 'booted' => { 'image_digest' => "sha256:#{SecureRandom.hex}" } }
                  }
                }
              end

              include_examples 'skips the job'
            end
          end

          it 'propagates enqueue failures' do
            allow(SystemImportJob).to receive(:perform_later).and_raise(StandardError, 'enqueue failed')

            expect { consumer.consume }.to raise_error(StandardError, 'enqueue failed')
          end
        end
      end
    end
  end
end
