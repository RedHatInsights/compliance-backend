# frozen_string_literal: true

require 'rails_helper'

describe Kafka::HostRemover do
  after do
    DeleteHost.clear
  end

  let(:service) { Kafka::HostRemover.new(message, Karafka.logger) }

  let(:type) { 'delete' }
  let(:user) { FactoryBot.create(:v2_user) }
  let(:org_id) { user.org_id }
  let(:system) do
    FactoryBot.create(
      :system,
      account: user.account
    )
  end
  let(:message) do
    {
      'type' => type,
      'id' => system.id,
      'timestamp' => DateTime.now.iso8601(6),
      'org_id' => org_id
    }
  end

  it 'enqueues system deletion' do
    expect(Karafka.logger).to receive(:audit_success).with(
      "[#{org_id}] Enqueued DeleteHost job for host #{system.id}"
    )

    service.remove_host

    expect(DeleteHost.jobs.size).to eq(1)
  end

  context 'enqueued system deletion fails' do
    before do
      allow(DeleteHost).to receive(:perform_async).and_raise(StandardError)
    end

    it 'handles error gracefully' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to enqueue DeleteHost job for host #{system.id}: StandardError"
      )

      expect { service.remove_host }.to raise_error(StandardError)
      expect(DeleteHost.jobs.size).to eq(0)
    end
  end
end
