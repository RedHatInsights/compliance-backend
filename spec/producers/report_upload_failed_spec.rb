# frozen_string_literal: true

require 'rails_helper'

describe ReportUploadFailed do
  let(:system) { FactoryBot.create(:system) }
  let(:request_id) { '1' }
  let(:org_id) { '001' }
  let(:error) { 'Upload failed due to network error.' }
  let(:event) do
    [{
      'metadata' => {},
      'payload' => {
        'host_id' => system.id,
        'host_name' => system.display_name,
        'request_id' => request_id,
        'error' => error
      }.to_json
    }]
  end

  it 'provides event details to notification' do
    ReportUploadFailed.deliver(
      host: system,
      request_id: request_id,
      error: error,
      org_id: org_id
    )

    sent_payload = JSON.parse(karafka.produced_messages.first[:payload])

    expect(karafka.produced_messages.size).to eq(1)
    expect(sent_payload.dig('events')).to match(array_including(event))
    expect(sent_payload['event_type']).to eq('report-upload-failed')
    expect(karafka.produced_messages.first[:topic]).to eq('platform.notifications.ingress')
  end
end
