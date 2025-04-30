# frozen_string_literal: true

require 'rails_helper'

describe Kafka::PolicySystemImporter do
  let(:service) { Kafka::PolicySystemImporter.new(message, Karafka.logger) }

  let(:user) { FactoryBot.create(:v2_user) }
  let(:org_id) { user.org_id }

  let(:policy_id) { FactoryBot.create(:v2_policy, os_major_version: 8, supports_minors: [0], empty_policy: true).id }
  let(:system_id) { FactoryBot.create(:system, account: user.account).id }

  let(:type) { 'create' }
  let(:message) do
    {
      'type' => type,
      'timestamp' => DateTime.now.iso8601(6),
      'host' => {
        'id' => system_id,
        'org_id' => org_id,
        'system_profile' => {
          'image_builder' => {
            'compliance_policy_id' => policy_id
          }
        }
      }
    }
  end

  it 'imports PolicySystem' do
    expect(V2::PolicySystem).to receive(:new).with(
      policy_id: policy_id,
      system_id: system_id
    ).and_return(instance_double(V2::PolicySystem, save!: true))

    expect(Karafka.logger).to receive(:audit_success).with(
      "[#{org_id}] Imported PolicySystem for System #{system_id}"
    )

    service.import
  end

  context 'received invalid system ID' do
    let(:system_id) { Faker::Internet.uuid }

    it 'handles and logs exception' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to import PolicySystem: System not found"
      )

      expect { service.import }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'received invalid policy ID' do
    let(:policy_id) { Faker::Internet.uuid }

    it 'handles and logs exception' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to import PolicySystem: Policy not found"
      )

      expect { service.import }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
