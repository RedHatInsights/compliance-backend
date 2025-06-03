# frozen_string_literal: true

require 'rails_helper'

describe ReportValidation do
  let(:request_id) { '1' }
  let(:service) { 'compliance' }
  let(:validation) { 'success' }

  describe 'provided a payload' do
    let(:correct_message) do
      {
        'request_id' => request_id,
        'service' => service,
        'validation' => validation
      }
    end

    it 'sends a correct message to the correct topic' do
      ReportValidation.deliver(
        request_id: request_id,
        service: service,
        validation: validation
      )

      expect(karafka.produced_messages.size).to eq(1)
      expect(JSON.parse(karafka.produced_messages.first[:payload])).to match(hash_including(correct_message))
      expect(karafka.produced_messages.first[:topic]).to eq('platform.upload.compliance')
    end
  end

  describe 'delivery fails' do
    before do
      allow(ReportValidation).to receive(:kafka).and_raise(Rdkafka::RdkafkaError.new(1))
    end

    it 'handles delivery issues' do
      expect(Rails.logger).to receive(:error).with(
        a_string_matching(
          /\AReportValidation delivery failed:/
        )
      )
      expect do
        ReportValidation.deliver(
          request_id: request_id,
          service: service,
          validation: validation
        )
      end.to_not raise_error
    end
  end
end
