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

    context 'when message is for compliance service' do
      let(:message) do
        super().deep_merge(
          {
            'platform_metadata' => {
              'service' => 'compliance'
            }
          }
        )
      end

      it 'delegates to ReportParser' do
        expect(Kafka::ReportParser).to receive(:new).with(message, anything).and_call_original
        expect_any_instance_of(Kafka::ReportParser).to receive(:parse_reports)

        consumer.consume
      end
    end
  end

  describe 'handling messages by type' do
    context 'when message is delete' do
      let(:type) { 'delete' }

      it 'enqueues SystemDeleteJob' do
        expect(SystemDeleteJob).to receive(:perform_later).with(message)

        consumer.consume
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
            expect(SystemImportJob).to receive(:perform_later).with(message)

            consumer.consume
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
