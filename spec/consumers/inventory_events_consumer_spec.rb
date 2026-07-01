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

  describe 'handling messages with unknown type' do
    let(:type) { 'somethingelse' }

    it 'logs a debug message and skips processing' do
      expect(Karafka.logger).to receive(:debug).with("Skipped message of type '#{type}'")

      consumer.consume
    end
  end

  describe 'handling messages after three retries' do
    let(:type) { 'delete' }

    before do
      allow(consumer).to receive(:attempt).and_return(4)
    end

    it 'logs and discards message' do
      expect(Karafka.logger).to receive(:error).with('Discarded message')

      consumer.consume
    end
  end

  describe 'handling messages by type' do
    context 'when message is delete' do
      let(:type) { 'delete' }

      it 'delegates to DeletedSystemCleaner service' do
        expect(Kafka::DeletedSystemCleaner).to receive(:new).with(message, anything).and_call_original
        expect_any_instance_of(Kafka::DeletedSystemCleaner).to receive(:cleanup_system)

        consumer.consume
      end
    end

    context 'when message is created or updated' do
      before do
        allow_any_instance_of(Kafka::SystemImporter).to receive(:import)
      end

      %w[created updated].each do |msg_type|
        context "with #{msg_type} message" do
          let(:type) { msg_type }

          context 'without policy_id and not compliance service' do
            it 'delegates to SystemImporter service only' do
              expect(Kafka::SystemImporter).to receive(:new).with(message, anything).and_call_original
              expect_any_instance_of(Kafka::SystemImporter).to receive(:import)

              expect(Kafka::PolicySystemImporter).not_to receive(:new)
              expect(Kafka::ReportParser).not_to receive(:new)

              consumer.consume
            end
          end

          context 'with policy_id' do
            let(:message) do
              super().deep_merge(
                {
                  'host' => {
                    'system_profile' => {
                      'image_builder' => {
                        'compliance_policy_id' => 'policy_id'
                      }
                    }
                  }
                }
              )
            end

            it 'delegates to SystemImporter and PolicySystemImporter' do
              expect(Kafka::SystemImporter).to receive(:new).with(message, anything).and_call_original
              expect_any_instance_of(Kafka::SystemImporter).to receive(:import)

              expect(Kafka::PolicySystemImporter).to receive(:new).with(message, anything).and_call_original
              expect_any_instance_of(Kafka::PolicySystemImporter).to receive(:import)

              expect(Kafka::ReportParser).not_to receive(:new)

              consumer.consume
            end
          end

          context 'with compliance service' do
            let(:message) do
              super().deep_merge(
                {
                  'platform_metadata' => {
                    'service' => 'compliance'
                  }
                }
              )
            end

            it 'delegates to SystemImporter and ReportParser' do
              expect(Kafka::SystemImporter).to receive(:new).with(message, anything).and_call_original
              expect_any_instance_of(Kafka::SystemImporter).to receive(:import)

              expect(Kafka::ReportParser).to receive(:new).with(message, anything).and_call_original
              expect_any_instance_of(Kafka::ReportParser).to receive(:parse_reports)

              expect(Kafka::PolicySystemImporter).not_to receive(:new)

              consumer.consume
            end
          end
        end
      end
    end

    context 'when host is not importable' do
      let(:type) { 'created' }
      let(:host_overrides) { {} }
      let(:message) do
        {
          'type' => type,
          'host' => {
            'id' => SecureRandom.uuid,
            'insights_id' => SecureRandom.uuid
          }.merge(host_overrides)
        }
      end

      shared_examples 'skips importers' do
        before { allow_any_instance_of(Kafka::SystemImporter).to receive(:import) }

        it 'does not call SystemImporter' do
          expect(Kafka::SystemImporter).not_to receive(:new)
          consumer.consume
        end

        it 'does not call PolicySystemImporter' do
          expect(Kafka::PolicySystemImporter).not_to receive(:new)
          consumer.consume
        end
      end

      context 'with blank insights_id' do
        let(:host_overrides) { { 'insights_id' => nil } }
        include_examples 'skips importers'
      end

      context 'with null UUID insights_id' do
        let(:host_overrides) { { 'insights_id' => described_class::NON_INSIGHTS_ID } }
        include_examples 'skips importers'
      end

      context 'with edge host_type' do
        let(:host_overrides) { { 'system_profile' => { 'host_type' => 'edge' } } }
        include_examples 'skips importers'
      end

      context 'with CentOS operating_system' do
        let(:host_overrides) do
          { 'system_profile' => { 'operating_system' => { 'name' => 'CentOS Linux' } } }
        end
        include_examples 'skips importers'
      end

      context 'with bootc image digest' do
        let(:host_overrides) do
          { 'system_profile' => { 'bootc_status' => { 'booted' => { 'image_digest' => 'sha256:abc' } } } }
        end
        include_examples 'skips importers'
      end

      context 'with edge host_type and compliance_policy_id' do
        let(:host_overrides) do
          {
            'system_profile' => {
              'host_type' => 'edge',
              'image_builder' => { 'compliance_policy_id' => SecureRandom.uuid }
            }
          }
        end
        include_examples 'skips importers'
      end
    end

    context 'when message is for compliance service but unknown type' do
      let(:type) { 'unknown_type' }
      let(:message) do
        super().deep_merge(
          {
            'platform_metadata' => {
              'service' => 'compliance'
            }
          }
        )
      end

      it 'delegates to ReportParser and skips SystemImporter' do
        expect(Kafka::ReportParser).to receive(:new).with(message, anything).and_call_original
        expect_any_instance_of(Kafka::ReportParser).to receive(:parse_reports)

        expect(Kafka::SystemImporter).not_to receive(:new)

        consumer.consume
      end
    end
  end
end
