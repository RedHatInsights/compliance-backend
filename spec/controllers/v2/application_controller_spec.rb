# frozen_string_literal: true

require 'rails_helper'

describe V2::ApplicationController do
  describe 'rbac_allowed?' do
    let(:user) { FactoryBot.build(:user) }
    let(:header) { OpenStruct.new(cert_based?: false, raw: nil) }
    let(:action_name) { 'index' }

    before do
      allow(subject).to receive(:user).and_return(user)
      allow(subject).to receive(:identity_header).and_return(header)
      allow(user.account).to receive(:identity_header).and_return(header)
      allow(subject).to receive(:action_name).and_return(action_name)
      allow(Rbac).to receive(:load_user_permissions).and_return(
        permissions.map do |permission|
          RBACApiClient::Access.new(
            permission: permission,
            resource_definitions: []
          )
        end
      )
      subject.class.instance_variable_set(:@action_permissions, { index: Rbac::COMPLIANCE_VIEWER })
    end

    context 'cert based auth' do
      let(:header) { OpenStruct.new(cert_based?: true) }
      let(:permissions) { [] }

      it 'calls valid_cert_auth?' do
        expect(subject).to receive(:valid_cert_auth?)
        subject.send(:rbac_allowed?)
      end
    end

    context 'with sufficient permissions' do
      let(:permissions) { [Rbac::INVENTORY_HOSTS_READ, Rbac::COMPLIANCE_VIEWER] }

      it 'returns true' do
        expect(subject.send(:rbac_allowed?)).to be true
      end
    end

    context 'with insufficient permission' do
      context 'when only inventory:groups:read is permitted' do
        let(:permissions) { ['inventory:groups:read', Rbac::COMPLIANCE_VIEWER] }

        it 'results in rejecting access' do
          expect(subject.send(:rbac_allowed?)).to be false
        end
      end

      context 'when compliance:policy:read permission is missing' do
        let(:permissions) { [Rbac::INVENTORY_HOSTS_READ] }

        it 'results in rejecting access' do
          expect(subject.send(:rbac_allowed?)).to be false
        end
      end

      context 'when inventory:hosts:read permission is missing' do
        let(:permissions) { [Rbac::COMPLIANCE_VIEWER] }

        it 'results in rejecting access' do
          expect(subject.send(:rbac_allowed?)).to be false
        end
      end
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
