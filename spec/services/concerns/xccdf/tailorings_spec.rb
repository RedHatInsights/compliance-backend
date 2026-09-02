# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::Tailorings do
  subject(:service) do
    Class.new do
      include Xccdf::Tailorings

      def initialize(policy:, system:, security_guide:)
        @policy = policy
        @system = system
        @security_guide = security_guide
      end

      attr_reader :security_guide
    end.new(policy: policy, system: system, security_guide: security_guide)
  end

  let(:os_minor_version) { 0 }
  let(:unsupported_os_minor_version) { os_minor_version + 1 }
  let(:user) { create(:user) }
  let(:policy) { create(:policy, account: user.account, supports_minors: [os_minor_version]) }
  let!(:system) { create(:system, account: user.account, policy_id: policy.id, os_minor_version: os_minor_version) }
  let(:tailoring_record) { Tailoring.find_by(policy_id: policy&.id, os_minor_version: system.os_minor_version) }
  let(:security_guide) { tailoring_record&.security_guide }

  describe '#tailoring' do
    it 'finds the tailoring matching the policy and system OS minor version' do
      expected = Tailoring.find_by!(policy_id: policy.id, os_minor_version: os_minor_version)

      expect(service.tailoring).to eq(expected)
    end

    context 'when no tailoring exists and the OS minor version is unsupported' do
      let!(:system) { create(:system, account: user.account, os_minor_version: unsupported_os_minor_version) }

      it 'returns nil' do
        expect(service.tailoring).to be_nil
      end
    end

    context 'when no tailoring exists but the OS minor version is supported by the profile' do
      let(:upgraded_os_minor_version) { os_minor_version + 1 }
      let(:policy) do
        create(:policy, account: user.account, supports_minors: [os_minor_version, upgraded_os_minor_version])
      end
      let!(:system) { create(:system, account: user.account, os_minor_version: upgraded_os_minor_version) }

      it 'auto-creates a tailoring for the OS minor version' do
        expect { service.tailoring }.to change(Tailoring, :count).by(1)
      end

      it 'returns a persisted tailoring matching the policy and OS minor version' do
        result = service.tailoring

        expect(result).to be_persisted
        expect(result.os_minor_version).to eq(upgraded_os_minor_version)
        expect(result.policy).to eq(policy)
      end

      it 'assigns the correct profile variant to the new tailoring' do
        result = service.tailoring
        expected_profile = policy.profile.variant_for_minor(upgraded_os_minor_version)

        expect(result.profile).to eq(expected_profile)
      end

      it 'populates the tailoring with rules from the canonical profile' do
        result = service.tailoring

        expect(result.tailoring_rules.pluck(:rule_id))
          .to match_array(ProfileRule.where(profile_id: result.profile_id).pluck(:rule_id))
      end

      it 'logs an audit message after persistence' do
        allow(Rails.logger).to receive(:audit_success)

        service.tailoring

        expect(Rails.logger).to have_received(:audit_success).with(/Auto-created tailoring/)
      end

      it 'does not log when the tailoring already exists' do
        service.tailoring

        allow(Rails.logger).to receive(:audit_success)

        service.class.new(policy: policy, system: system, security_guide: security_guide).tailoring

        expect(Rails.logger).not_to have_received(:audit_success)
      end
    end
  end

  describe '#external_report?' do
    it 'returns false when a policy is present' do
      expect(service.external_report?).to be false
    end

    context 'when policy is nil' do
      let(:policy) { nil }
      let!(:system) { create(:system, account: user.account) }

      it 'returns true' do
        expect(service.external_report?).to be true
      end
    end
  end

  describe '#version_mismatched?' do
    context 'when the security guide matches the tailoring profile' do
      it 'returns false' do
        expect(service.version_mismatched?).to be false
      end
    end

    context 'when the security guide differs from the tailoring profile' do
      let(:security_guide) { create(:security_guide) }

      it 'returns true' do
        expect(service.version_mismatched?).to be true
      end
    end

    context 'when no tailoring exists' do
      let!(:system) { create(:system, account: user.account, os_minor_version: unsupported_os_minor_version) }

      it 'returns false' do
        expect(service.version_mismatched?).to be false
      end
    end
  end

  describe '#tailored_profile' do
    it 'returns the profile associated with the tailoring' do
      expected = Tailoring.find_by!(policy_id: policy.id, os_minor_version: os_minor_version).profile

      expect(service.tailored_profile).to eq(expected)
    end

    context 'when no tailoring exists for the system OS minor version' do
      let!(:system) { create(:system, account: user.account, os_minor_version: unsupported_os_minor_version) }

      it 'raises OSVersionMismatch instead of NoMethodError' do
        expect { service.tailored_profile }
          .to raise_error(XccdfReportParser::OSVersionMismatch)
      end
    end

    context 'when the OS minor version is supported but has no tailoring yet' do
      let(:upgraded_os_minor_version) { os_minor_version + 1 }
      let(:policy) do
        create(:policy, account: user.account, supports_minors: [os_minor_version, upgraded_os_minor_version])
      end
      let!(:system) { create(:system, account: user.account, os_minor_version: upgraded_os_minor_version) }

      it 'returns the profile from the auto-created tailoring' do
        result = service.tailored_profile
        expected_profile = policy.profile.variant_for_minor(upgraded_os_minor_version)

        expect(result).to eq(expected_profile)
      end
    end
  end
end
