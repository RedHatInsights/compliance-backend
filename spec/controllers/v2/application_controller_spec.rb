# frozen_string_literal: true

require 'rails_helper'

describe V2::ApplicationController do
  describe 'rbac_allowed?' do
    let(:user) { User.new }
    let(:header) { OpenStruct.new(cert_based?: false) }
    let(:action_name) { 'index' }

    before do
      allow(subject).to receive(:user).and_return(user)
      allow(subject).to receive(:identity_header).and_return(header)
      allow(subject).to receive(:action_name).and_return(action_name)
      allow(user).to receive(:authorized_to?).with(Rbac::INVENTORY_VIEWER).and_return(true)
      allow(user).to receive(:authorized_to?).with(Rbac::COMPLIANCE_VIEWER).and_return(true)
    end

    context 'cert based auth' do
      let(:header) { OpenStruct.new(cert_based?: true) }

      it 'calls valid_cert_auth?' do
        expect(subject).to receive(:valid_cert_auth?)
        subject.send(:rbac_allowed?)
      end
    end

    it 'returns true with correct permissions' do
      subject.class.instance_variable_set(:@action_permissions, { index: Rbac::COMPLIANCE_VIEWER })

      expect(subject.send(:rbac_allowed?)).to be_truthy
    end
  end

  describe 'audit_success' do
    let(:message) { 'msg' }
    it 'calls Rails.logger.audit_success' do
      expect(Rails.logger).to receive(:audit_success).with(message)
      subject.send(:audit_success, message)
    end
  end
end
