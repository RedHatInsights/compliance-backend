# frozen_string_literal: true

require 'rails_helper'

describe Kafka::DeletedSystemCleaner do
  let(:service) { Kafka::DeletedSystemCleaner.new(message, Karafka.logger) }

  let(:type) { 'delete' }
  let(:user) { FactoryBot.create(:user) }
  let(:org_id) { user.org_id }
  let(:policy) { FactoryBot.create(:policy, account: user.account, supports_minors: [0]) }
  let(:system) { FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0) }
  let!(:kafka_system) { FactoryBot.create(:kafka_system, id: system.id, account: '12345', org_id: org_id) }
  let!(:test_result) { FactoryBot.create(:test_result, system: system, report_id: policy.id) }
  let(:message) do
    {
      'type' => type,
      'id' => system.id,
      'org_id' => org_id
    }
  end

  it 'performs and logs cleanup' do
    expect(Karafka.logger).to receive(:audit_success).with(
      "[#{org_id}] Deleted related records for System #{system.id}"
    )

    expect { service.cleanup_system }.to(
      change { HistoricalTestResult.where(system_id: system.id).count }.from(1).to(0)
      .and(change { policy.systems.count }.from(1).to(0))
    )
  end

  context 'with multiple systems under a policy' do
    let(:extra_system) { FactoryBot.create(:system, account: user.account, policy_id: policy.id, os_minor_version: 0) }
    let!(:extra_kafka_system) do
      FactoryBot.create(:kafka_system, id: extra_system.id, account: Faker::Number.number(digits: 5).to_s,
                                       org_id: org_id)
    end
    let!(:extra_test_result) { FactoryBot.create(:test_result, system: extra_system, report_id: policy.id) }

    it 'performs and logs cleanup for the specific system' do
      expect(Karafka.logger).to receive(:audit_success).with(
        "[#{org_id}] Deleted related records for System #{system.id}"
      )

      expect { service.cleanup_system }.to(
        change { HistoricalTestResult.where(system_id: system.id).count }.from(1).to(0)
        .and(change { policy.systems.count }.from(2).to(1))
      )

      expect(HistoricalTestResult.where(system_id: extra_system.id).count).to eql(1)
      expect(KafkaSystem.where(id: extra_system.id).count).to eql(1)
    end
  end

  context 'when there are no records tied to the deleted system' do
    let(:lonely_system) { FactoryBot.create(:system, account: user.account, os_minor_version: 0) }
    let(:message) do
      {
        'type' => type,
        'id' => lonely_system.id,
        'org_id' => org_id
      }
    end

    it 'does not perform cleanup and does not log' do
      expect(Karafka.logger).not_to receive(:audit_success)

      expect do
        service.cleanup_system
      end.not_to(change { KafkaSystem.count })

      # Ensure it doesn't try to delete the view either
      expect do
        service.cleanup_system
      end.not_to(change { System.count })
    end
  end

  context 'when deletion is not possible' do
    before do
      allow(service).to receive(:remove_related).and_raise(StandardError)
    end

    it 'logs failure and raises and error' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to delete related records for System #{system.id}: StandardError"
      )

      expect { service.cleanup_system }.to raise_error(StandardError)
    end
  end
end
