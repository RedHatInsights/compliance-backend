# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Xccdf::Tailorings do
  subject(:service) do
    Class.new do
      include Xccdf::Tailorings

      def initialize(policy:, system:)
        @policy = policy
        @system = system
      end
    end.new(policy: policy, system: system)
  end

  let(:os_minor_version) { 0 }
  let(:unsupported_os_minor_version) { os_minor_version + 1 }
  let(:user) { create(:v2_user) }
  let(:policy) { create(:v2_policy, account: user.account, supports_minors: [os_minor_version]) }
  let!(:system) { create(:system, account: user.account, policy_id: policy.id, os_minor_version: os_minor_version) }

  describe '#tailoring' do
    it 'finds the tailoring matching the policy and system OS minor version' do
      expected = V2::Tailoring.find_by!(policy_id: policy.id, os_minor_version: os_minor_version)

      expect(service.tailoring).to eq(expected)
    end

    context 'when no tailoring exists for the system OS minor version' do
      let!(:system) { create(:system, account: user.account, os_minor_version: unsupported_os_minor_version) }

      it 'returns nil' do
        expect(service.tailoring).to be_nil
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

  describe '#tailored_profile' do
    it 'returns the profile associated with the tailoring' do
      expected = V2::Tailoring.find_by!(policy_id: policy.id, os_minor_version: os_minor_version).profile

      expect(service.tailored_profile).to eq(expected)
    end

    context 'when no tailoring exists for the system OS minor version' do
      let!(:system) { create(:system, account: user.account, os_minor_version: unsupported_os_minor_version) }

      it 'raises OSVersionMismatch instead of NoMethodError' do
        expect { service.tailored_profile }
          .to raise_error(XccdfReportParser::OSVersionMismatch)
      end
    end
  end
end
