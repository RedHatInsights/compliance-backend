# frozen_string_literal: true

require 'rails_helper'

describe ApplicationConsumer do
  subject(:consumer) { karafka.consumer_for(Settings.kafka.topics.inventory_events) }

  let(:message) do
    {
      'type' => 'delete',
      'host' => {
        'id' => Faker::Internet.uuid,
        'insights_id' => Faker::Internet.uuid
      }
    }
  end

  before { karafka.produce(message.to_json) }

  describe '#consume' do
    before { allow_any_instance_of(Kafka::DeletedSystemCleaner).to receive(:cleanup_system) }

    it 'wraps processing in the Rails executor for connection and state management' do
      expect(Rails.application.executor).to receive(:wrap).and_call_original
      consumer.consume
    end

    context 'when an error is raised during message processing' do
      before { allow(consumer).to receive(:consume_one).and_raise(StandardError) }

      it 'propagates the error outside the executor wrap' do
        expect(Rails.application.executor).to receive(:wrap).and_call_original
        expect { consumer.consume }.to raise_error(StandardError)
      end
    end
  end
end
