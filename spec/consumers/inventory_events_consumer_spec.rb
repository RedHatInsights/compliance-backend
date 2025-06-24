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

  describe 'handling updated messages for different service' do
    let(:type) { 'updated' }
    let(:message) do
      super().deep_merge(
        {
          'platform_metadata' => {
            'service' => 'non-compliance'
          }
        }
      )
    end

    it 'logs a debug message and skips processing' do
      expect(Karafka.logger).to receive(:debug).with("Skipped message of type '#{type}'")

      consumer.consume
    end
  end

  describe 'handling messages without policy ID' do
    context 'message is created' do
      let(:type) { 'created' }

      it 'logs a debug message and skips processing' do
        expect(Karafka.logger).to receive(:debug).with("Skipped message of type '#{type}'")

        consumer.consume
      end
    end

    context 'message is updated' do
      let(:type) { 'updated' }

      it 'logs a debug message and skips processing' do
        expect(Karafka.logger).to receive(:debug).with("Skipped message of type '#{type}'")

        consumer.consume
      end
    end
  end

  describe 'routing to the appropriate service' do
    before do
      @service = instance_double(service_class)
      allow(service_class).to receive(:new).and_return(@service)
    end

    context 'received compliance message' do
      let(:service_class) { Kafka::ReportParser }
      let(:type) { 'updated' }
      let(:message) do
        super().deep_merge(
          {
            'platform_metadata' => {
              'service' => 'compliance'
            }
          }
        )
      end

      it 'delegates to ReportParser service' do
        allow(@service).to receive(:parse_reports)

        expect(@service).to receive(:parse_reports)

        consumer.consume
      end
    end

    context 'received delete message' do
      let(:service_class) { Kafka::DeletedHostCleaner }
      let(:type) { 'delete' }

      it 'delegates to DeletedHostCleaner service' do
        allow(@service).to receive(:cleanup_host)

        expect(@service).to receive(:cleanup_host)

        consumer.consume
      end
    end

    context 'receives message with a policy ID' do
      let(:service_class) { Kafka::PolicySystemImporter }
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

      context 'message is created' do
        let(:type) { 'created' }

        it 'delegates to PolicySystemImporter service' do
          allow(@service).to receive(:import)

          expect(@service).to receive(:import)

          consumer.consume
        end
      end

      context 'message is updated' do
        let(:type) { 'updated' }

        it 'delegates to PolicySystemImporter service' do
          allow(@service).to receive(:import)

          expect(@service).to receive(:import)

          consumer.consume
        end
      end
    end
  end
end
