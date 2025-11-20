# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KesselRbac, type: :service do
  let(:user) { create(:v2_user) }
  let(:org_id) { user.org_id }

  describe '.check_permission' do
    let(:mock_client) { double('kessel_client') }
    let(:mock_response) { double('response', allowed: Kessel::Inventory::V1beta2::Allowed::ALLOWED_TRUE) }

    before do
      allow(KesselRbac).to receive(:enabled?).and_return(true)
      allow(described_class).to receive(:client).and_return(mock_client)
    end

    it 'fails if an invalid user identity is supplied' do
      expect do
        described_class.check_permission(
          resource_type: 'workspace',
          resource_id: 'test-workspace',
          permission: 'compliance_policy_view',
          user: create(:v2_user, :with_invalid_identity_type)
        )
      end.to raise_error('unsupported identity type')
    end

    context 'when permission is granted' do
      before do
        allow(mock_client).to receive(:check).and_return(mock_response)
      end

      it 'accepts service accounts' do
        result = described_class.check_permission(
          resource_type: 'workspace',
          resource_id: 'test-workspace',
          permission: 'compliance_policy_view',
          user: user
        )

        expect(result).to be true
      end

      it 'returns true' do
        result = described_class.check_permission(
          resource_type: 'workspace',
          resource_id: 'test-workspace',
          permission: 'compliance_policy_view',
          user: user
        )

        expect(result).to be true
      end
    end

    context 'when permission is denied' do
      let(:mock_response) { double('response', allowed: Kessel::Inventory::V1beta2::Allowed::ALLOWED_FALSE) }

      before do
        allow(mock_client).to receive(:check).and_return(mock_response)
      end

      it 'returns false' do
        result = described_class.check_permission(
          resource_type: 'workspace',
          resource_id: 'test-workspace',
          permission: 'compliance_policy_view',
          user: user
        )

        expect(result).to be false
      end
    end

    context 'when Kessel is disabled' do
      before do
        allow(KesselRbac).to receive(:enabled?).and_return(false)
      end

      it 'returns true (bypasses Kessel)' do
        result = described_class.check_permission(
          resource_type: 'workspace',
          resource_id: 'test-workspace',
          permission: 'compliance_policy_view',
          user: user
        )

        expect(result).to be true
      end
    end

    context 'when permission contains write operations' do
      before do
        allow(mock_client).to receive(:check_for_update).and_return(mock_response)
      end

      it 'calls check_for_update method for write operations' do
        described_class.check_permission(
          resource_type: 'workspace',
          resource_id: 'test-workspace',
          permission: 'compliance_policy_write',
          user: user
        )

        expect(mock_client).to have_received(:check_for_update)
      end
    end

    context 'when Kessel client raises an error' do
      before do
        allow(mock_client).to receive(:check).and_raise(StandardError, 'Connection failed')
      end

      it 'raises AuthorizationError' do
        expect do
          described_class.check_permission(
            resource_type: 'workspace',
            resource_id: 'test-workspace',
            permission: 'compliance_policy_view',
            user: user
          )
        end.to raise_error(KesselRbac::AuthorizationError, /Authorization check failed/)
      end
    end
  end

  describe '.list_workspaces_with_permission' do
    let(:mock_client) { double('kessel_client') }
    let(:mock_response) do
      [double('object', object: double('object', resource_id: 'workspace-1')),
       double('object', object: double('object', resource_id: 'workspace-2'))]
    end

    before do
      allow(KesselRbac).to receive(:enabled?).and_return(true)
      allow(described_class).to receive(:client).and_return(mock_client)
      allow(mock_client).to receive(:streamed_list_objects).and_return(mock_response)
    end

    it 'returns workspace IDs' do
      result = described_class.list_workspaces_with_permission(
        permission: 'inventory_host_view',
        user: user
      )

      expect(result).to eq(%w[workspace-1 workspace-2])
    end

    context 'when Kessel is disabled' do
      before do
        allow(KesselRbac).to receive(:enabled?).and_return(false)
      end

      it 'returns empty array' do
        result = described_class.list_workspaces_with_permission(
          permission: 'inventory_host_view',
          user: user
        )

        expect(result).to eq([])
      end
    end
  end

  describe '.get_default_workspace_id' do
    let(:auth) { double('oauth_credentials') }
    let(:identity_header) { user.account.identity_header.raw }
    let(:workspace_id) { "default-workspace-#{org_id}" }

    before do
      allow(KesselUtils).to receive(:get_default_workspace_id).and_return(workspace_id)
    end

    it 'delegates to KesselUtils and returns workspace ID' do
      result = described_class.get_default_workspace_id(auth, identity_header)
      expect(result).to eq(workspace_id)
      expect(KesselUtils).to have_received(:get_default_workspace_id).with(auth, identity_header)
    end
  end

  describe '.default_permission_allowed?' do
    let(:permission) { 'compliance_policy_view' }
    let(:workspace_id) { "default-workspace-#{org_id}" }
    let(:auth) { double('oauth_credentials') }

    before do
      allow(KesselRbac).to receive(:enabled?).and_return(true)
      allow(described_class).to receive(:get_default_workspace_id).and_return(workspace_id)
      allow(described_class).to receive(:check_permission).and_return(true)
      allow(described_class).to receive(:auth).and_return(auth)
    end

    context 'when user has permission' do
      it 'returns true' do
        result = described_class.default_permission_allowed?(permission, user)
        expect(result).to be true
      end

      it 'calls check_permission with workspace context' do
        described_class.default_permission_allowed?(permission, user)

        expect(described_class).to have_received(:check_permission).with(
          resource_type: 'workspace',
          resource_id: workspace_id,
          permission: permission,
          user: user
        )
      end
    end

    context 'when permission contains write or delete' do
      let(:permission) { 'compliance_policy_write' }

      it 'calls check_permission for write permission' do
        described_class.default_permission_allowed?(permission, user)

        expect(described_class).to have_received(:check_permission).with(
          resource_type: 'workspace',
          resource_id: workspace_id,
          permission: permission,
          user: user
        )
      end
    end

    context 'when permission is nil' do
      it 'returns false' do
        result = described_class.default_permission_allowed?(nil, user)
        expect(result).to be false
      end
    end

    context 'when authorization fails' do
      before do
        allow(described_class).to receive(:check_permission).and_raise(KesselRbac::AuthorizationError, 'Test error')
        allow(Rails.logger).to receive(:error)
      end

      it 'raises if check_permission raises' do
        expect do
          described_class.default_permission_allowed?(permission, user)
        end.to raise_error(KesselRbac::AuthorizationError)
      end
    end
  end
end
