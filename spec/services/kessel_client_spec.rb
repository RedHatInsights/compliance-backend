# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KesselClient, type: :service do
  let(:user) { create(:v2_user) }
  let(:org_id) { user.org_id }

  before do
    # Mock Kessel SDK classes
    stub_const('Kessel::Configuration', Class.new)
    stub_const('Kessel::ApiClient', Class.new)
    stub_const('Kessel::KesselInventoryService', Class.new)
    stub_const('Kessel::ResourceReference', Class.new)
    stub_const('Kessel::ReporterReference', Class.new)
    stub_const('Kessel::SubjectReference', Class.new)
    stub_const('Kessel::RepresentationType', Class.new)
  end

  describe '.enabled?' do
    context 'when Kessel is enabled in settings' do
      before { allow(Settings.kessel).to receive(:enabled).and_return(true) }

      it 'returns true' do
        expect(described_class.enabled?).to be true
      end
    end

    context 'when Kessel is disabled in settings' do
      before { allow(Settings.kessel).to receive(:enabled).and_return(false) }

      it 'returns false' do
        expect(described_class.enabled?).to be false
      end
    end
  end

  describe '.check_permission' do
    let(:mock_client) { double('kessel_client') }
    let(:mock_response) { double('response', allowed: true) }

    before do
      allow(described_class).to receive(:enabled?).and_return(true)
      allow(described_class).to receive(:client).and_return(mock_client)
    end

    context 'when permission is granted' do
      before do
        allow(mock_client).to receive(:check).and_return(mock_response)
      end

      it 'fails on invalid identity' do
        expect do
          described_class.check_permission(
            resource_type: 'workspace',
            resource_id: 'test-workspace',
            permission: 'compliance_policy_view',
            user: create(:v2_user, :with_invalid_identity_type)
          )
        end.to raise_error('unsupported identity type')
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
      let(:mock_response) { double('response', allowed: false) }

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
        allow(described_class).to receive(:enabled?).and_return(false)
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

    context 'when using check_for_update' do
      before do
        allow(mock_client).to receive(:check_for_update).and_return(mock_response)
      end

      it 'calls check_for_update method' do
        described_class.check_permission(
          resource_type: 'workspace',
          resource_id: 'test-workspace',
          permission: 'compliance_policy_write',
          user: user,
          use_check_for_update: true
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
        end.to raise_error(KesselClient::AuthorizationError, /Authorization check failed/)
      end
    end
  end

  describe '.list_workspaces_with_permission' do
    let(:mock_client) { double('kessel_client') }
    let(:mock_response) { [double('object', resource_id: 'workspace-1'), double('object', resource_id: 'workspace-2')] }

    before do
      allow(described_class).to receive(:enabled?).and_return(true)
      allow(described_class).to receive(:client).and_return(mock_client)
      allow(mock_client).to receive(:streamed_list_objects).and_return(mock_response)
    end

    it 'returns workspace IDs' do
      result = described_class.list_workspaces_with_permission(
        permission: 'inventory_hosts_view',
        user: user
      )

      expect(result).to eq(%w[workspace-1 workspace-2])
    end

    context 'when Kessel is disabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it 'returns empty array' do
        result = described_class.list_workspaces_with_permission(
          permission: 'inventory_hosts_view',
          user: user
        )

        expect(result).to eq([])
      end
    end
  end

  describe '.get_default_workspace_id' do
    let(:identity_header) { user.account.identity_header.raw }
    let(:workspace_id) { "default-workspace-#{org_id}" }

    before do
      allow(Rbac).to receive(:get_default_workspace_id).and_return(workspace_id)
    end

    it 'delegates to Rbac service and returns workspace ID' do
      result = described_class.get_default_workspace_id(identity_header)
      expect(result).to eq(workspace_id)
      expect(Rbac).to have_received(:get_default_workspace_id).with(identity_header)
    end
  end

  describe '.get_root_workspace_id' do
    let(:identity_header) { user.account.identity_header.raw }
    let(:workspace_id) { "root-workspace-#{org_id}" }

    before do
      allow(Rbac).to receive(:get_root_workspace_id).and_return(workspace_id)
    end

    it 'delegates to Rbac service and returns workspace ID' do
      result = described_class.get_root_workspace_id(identity_header)
      expect(result).to eq(workspace_id)
      expect(Rbac).to have_received(:get_root_workspace_id).with(identity_header)
    end
  end

  describe 'permission mapping' do
    it 'maps RBAC v1 permissions to Kessel compound permissions' do
      expect(described_class::PERMISSION_MAPPINGS['compliance:policy:read']).to eq('compliance_policy_view')
      expect(described_class::PERMISSION_MAPPINGS['compliance:*:*']).to eq('compliance_all_all')
      expect(described_class::PERMISSION_MAPPINGS['inventory:hosts:read']).to eq('inventory_hosts_view')
    end
  end
end
