# frozen_string_literal: true

require 'rails_helper'

describe Kafka::PolicySystemImporter do
  let(:service) { Kafka::PolicySystemImporter.new(message, Karafka.logger) }

  let(:user) { FactoryBot.create(:user) }
  let(:org_id) { user.org_id }

  let(:policy_id) { FactoryBot.create(:policy, os_major_version: 8, supports_minors: [0], empty_policy: true).id }
  let(:system_id) { FactoryBot.create(:system, account: user.account).id }

  # RHEL-8 ships per-minor datastreams here, so SupportedSsg runs for real (not minor-agnostic)
  # and resolve_minor keeps the requested minor. Stubbing the data instead of the methods keeps
  # this spec able to catch a wrong-major argument or a minor-agnostic regression.
  before do
    allow(SupportedSsg).to receive(:all).and_return(
      [
        SupportedSsg.new(os_major_version: '8', os_minor_version: '0', version: '0.1.72'),
        SupportedSsg.new(os_major_version: '8', os_minor_version: '1', version: '0.1.73')
      ]
    )
  end

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
    expect(Karafka.logger).to receive(:audit_success).with(
      "[#{org_id}] Imported PolicySystem for System #{system_id} from #{type} message"
    )

    expect { service.import }.to change(PolicySystem, :count).by(1)
  end

  context 'received invalid system ID' do
    let(:system_id) { Faker::Internet.uuid }

    it 'raises and logs exception' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to import PolicySystem: System not found with ID #{system_id}"
      )

      expect { service.import }.to raise_error(ActiveRecord::RecordNotFound)
      expect(PolicySystem.count).to eq(0)
    end
  end

  context 'received invalid policy ID' do
    let(:policy_id) { Faker::Internet.uuid }

    it 'logs error message and does not link System to Policy' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to import PolicySystem: Policy not found with ID #{policy_id}"
      )

      expect { service.import }.not_to change(PolicySystem, :count)
    end
  end

  context 'received incompatible policy' do
    let(:policy_id) { FactoryBot.create(:policy, os_major_version: 7, supports_minors: [0], empty_policy: true).id }

    it 'logs error message and does not link System to Policy' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to import PolicySystem: System Unsupported OS major version"
      )

      expect { service.import }.not_to change(PolicySystem, :count)
    end
  end

  context 'when PolicySystem already exists' do
    before do
      FactoryBot.create(:policy_system, policy_id: policy_id, system_id: system_id)
    end

    it 'logs error message and does not link System to Policy' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        a_string_including("[#{org_id}] Failed to import PolicySystem: System has already been taken")
      )

      expect { service.import }.not_to change(PolicySystem, :count)
    end
  end
end
