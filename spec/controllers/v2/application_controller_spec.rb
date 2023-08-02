# frozen_string_literal: true

require 'rails_helper'

describe V2::ApplicationController do
  describe 'rbac_allowed?' do
    let(:user) { User.new }
    let(:header) { OpenStruct.new(cert_based?: false, raw: nil) }
    let(:action_name) { 'index' }

    before do
      allow(subject).to receive(:user).and_return(user)
      allow(subject).to receive(:identity_header).and_return(header)
      allow(user.account).to receive(:identity_header).and_return(header)
      allow(subject).to receive(:action_name).and_return(action_name)
    end

    context 'cert based auth' do
      let(:header) { OpenStruct.new(cert_based?: true) }

      it 'calls valid_cert_auth?' do
        expect(subject).to receive(:valid_cert_auth?)
        subject.send(:rbac_allowed?)
      end
    end

    context 'with sufficient permissions' do
      before do
        permissions = [
          RBACApiClient::Access.new(
            permission: Rbac::INVENTORY_HOSTS_READ,
            resource_definitions: []
          ),
          RBACApiClient::Access.new(
            permission: Rbac::COMPLIANCE_VIEWER,
            resource_definitions: []
          )
        ]
        allow(Rbac).to receive(:load_user_permissions).and_return(permissions)
      end

      it 'returns true with correct permissions' do
        subject.class.instance_variable_set(:@action_permissions, { index: Rbac::COMPLIANCE_VIEWER })

        expect(subject.send(:rbac_allowed?)).to be_truthy
      end
    end

    context 'with insufficient permission to inventory' do
      before do
        permissions = [
          RBACApiClient::Access.new(
            permission: 'inventory:groups:read', # insufficient to access hosts
            resource_definitions: []
          ),
          RBACApiClient::Access.new(
            permission: Rbac::COMPLIANCE_VIEWER,
            resource_definitions: []
          )
        ]
        allow(Rbac).to receive(:load_user_permissions).and_return(permissions)
      end

      it 'results in rejecting access' do
        subject.class.instance_variable_set(:@action_permissions, { index: Rbac::COMPLIANCE_VIEWER })

        expect(subject.send(:rbac_allowed?)).to be_falsey
      end

      before do
        permissions = [
          RBACApiClient::Access.new(
            permission: Rbac::INVENTORY_HOSTS_READ,
            resource_definitions: []
          ), # insufficient to access hosts
        ]
        allow(Rbac).to receive(:load_user_permissions).and_return(permissions)
      end

      it 'results in rejecting access' do
        subject.class.instance_variable_set(:@action_permissions, { index: Rbac::COMPLIANCE_VIEWER })

        expect(subject.send(:rbac_allowed?)).to be_falsey
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
