# frozen_string_literal: true

require 'rails_helper'

describe ApplicationProducer do
  class MockProducer < ApplicationProducer
    TOPIC = 'mock.topic'

    def self.deliver(msg)
      deliver_message(msg)
    end
  end

  describe 'provided a payload' do
    let(:date) { DateTime.now.utc.send(:iso8601) }
    let(:service) { 'compliance' }
    let(:source) { ENV.fetch('APPLICATION_TYPE', nil) }

    let(:correct_message) do
      {
        date: date,
        service: service,
        source: source
      }.to_json
    end

    it 'enriches message and sends message' do
      MockProducer.deliver({})

      expect(karafka.produced_messages.size).to eq(1)
      expect(karafka.produced_messages.first[:payload]).to eq(correct_message)
      expect(karafka.produced_messages.first[:topic]).to eq('mock.topic')
    end
  end
end
