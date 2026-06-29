# frozen_string_literal: true

require 'rails_helper'

describe InventoryEventsConsumer do
  subject(:consumer) { karafka.consumer_for(Settings.kafka.topics.inventory_events) }

  before do
    karafka.produce(message.to_json)
  end

  let(:message) do
    {
      'type' => type
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
        service = instance_double(Kafka::DeletedSystemCleaner)
        allow(Kafka::DeletedSystemCleaner).to receive(:new).and_return(service)
        expect(service).to receive(:cleanup_system)

        consumer.consume
      end
    end

    context 'when message is created or updated' do
      before do
        @system_importer_service = instance_double(Kafka::SystemImporter)
        allow(Kafka::SystemImporter).to receive(:new).and_return(@system_importer_service)
        allow(@system_importer_service).to receive(:import)
      end

      %w[created updated].each do |msg_type|
        context "with #{msg_type} message" do
          let(:type) { msg_type }

          context 'without policy_id and not compliance service' do
            it 'delegates to SystemImporter service only' do
              expect(@system_importer_service).to receive(:import)
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
              policy_importer_service = instance_double(Kafka::PolicySystemImporter)
              allow(Kafka::PolicySystemImporter).to receive(:new).and_return(policy_importer_service)

              expect(@system_importer_service).to receive(:import)
              expect(policy_importer_service).to receive(:import)
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
              report_parser_service = instance_double(Kafka::ReportParser)
              allow(Kafka::ReportParser).to receive(:new).and_return(report_parser_service)

              expect(@system_importer_service).to receive(:import)
              expect(report_parser_service).to receive(:parse_reports)
              expect(Kafka::PolicySystemImporter).not_to receive(:new)

              consumer.consume
            end
          end
        end
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
        report_parser_service = instance_double(Kafka::ReportParser)
        allow(Kafka::ReportParser).to receive(:new).and_return(report_parser_service)

        expect(report_parser_service).to receive(:parse_reports)
        expect(Kafka::SystemImporter).not_to receive(:new)

        consumer.consume
      end
    end
  end
end
