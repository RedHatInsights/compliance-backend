# frozen_string_literal: true

require 'rails_helper'

describe ComplianceConsumer do
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
      expect(Karafka.logger).to receive(:debug).with("Skipped message of type #{type}")

      consumer.consume
    end
  end

  context 'routing to the appropriate service' do
    before do
      @service = instance_double(service_class)
      allow(service_class).to receive(:new).and_return(@service)
    end

    describe 'received compliance message' do
      let(:service_class) { ReportParser }
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
        allow(@service).to receive(:parse_report)

        expect(@service).to receive(:parse_report)

        consumer.consume
      end
    end

    describe 'received delete message' do
      let(:service_class) { Kafka::HostRemover }
      let(:type) { 'delete' }

      it 'delegates to HostRemover service' do
        allow(@service).to receive(:remove_host)

        expect(@service).to receive(:remove_host)

        consumer.consume
      end
    end

    describe 'received create message' do
      let(:service_class) { Kafka::PolicySystemImporter }
      let(:type) { 'created' }
      let(:message) do
        super().deep_merge(
          {
            'host' => {
              'image_builder' => {
                'compliance_policy_id' => 'policy_id'
              }
            }
          }
        )
      end

      it 'delegates to PolicySystemImporter service' do
        allow(@service).to receive(:import)

        expect(@service).to receive(:import)

        consumer.consume
      end
    end
  end
end
