# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'Kessel integration' do
    before do
      # Mock KesselClient
      allow(KesselClient).to receive(:enabled?).and_return(true)
    end

    describe '#authorized_to?' do
      let(:permission) { 'compliance:policy:read' }

      context 'when Kessel is enabled' do
        context 'when user is authorized' do
          let(:workspace_id) { "default-workspace-#{user.org_id}" }

          before do
            # Mock the Rbac service workspace lookup
            allow(Rbac).to receive(:get_default_workspace_id).and_return(workspace_id)
            allow(KesselClient).to receive(:check_permission).and_return(true)
          end

          it 'returns true' do
            expect(user.authorized_to?(permission)).to be true
          end

          it 'calls KesselClient with correct parameters' do
            user.authorized_to?(permission)

            expect(KesselClient).to have_received(:check_permission).with(
              resource_type: 'workspace',
              resource_id: workspace_id,
              permission: permission,
              user: user
            )
          end

          it 'calls Rbac service to get workspace ID' do
            user.authorized_to?(permission)

            expect(Rbac).to have_received(:get_default_workspace_id).with(user.account.identity_header.raw)
          end
        end

        context 'when user is not authorized' do
          before do
            # Mock the Rbac service workspace lookup
            allow(Rbac).to receive(:get_default_workspace_id).and_return("default-workspace-#{user.org_id}")
            allow(KesselClient).to receive(:check_permission).and_return(false)
          end

          it 'returns false' do
            expect(user.authorized_to?(permission)).to be false
          end
        end

        context 'when KesselClient raises an error' do
          before do
            # Mock the Rbac service workspace lookup
            allow(Rbac).to receive(:get_default_workspace_id).and_return("default-workspace-#{user.org_id}")
            allow(KesselClient).to receive(:check_permission).and_raise(KesselClient::AuthorizationError, 'Test error')
            allow(Rails.logger).to receive(:error)
          end

          it 'returns false and logs error' do
            expect(user.authorized_to?(permission)).to be false
            expect(Rails.logger).to have_received(:error).with(/Kessel authorization failed/)
          end
        end
      end

      context 'when Kessel is disabled' do
        before do
          allow(KesselClient).to receive(:enabled?).and_return(false)
          allow(user).to receive(:rbac_permissions).and_return([
                                                                 double('permission',
                                                                        permission: 'compliance:policy:read')
                                                               ])
          allow(Rbac).to receive(:verify).and_return(true)
        end

        it 'falls back to RBAC v1' do
          expect(user.authorized_to?(permission)).to be true
          expect(Rbac).to have_received(:verify)
        end
      end

      context 'when RBAC is disabled globally' do
        before do
          allow(Settings).to receive(:disable_rbac).and_return(true)
        end

        it 'returns true regardless of Kessel status' do
          expect(user.authorized_to?(permission)).to be true
        end
      end
    end

    describe '#inventory_groups' do
      context 'when Kessel is enabled' do
        before do
          allow(KesselClient).to receive(:enabled?).and_return(true)
        end

        context 'when user has workspace access' do
          before do
            allow(KesselClient).to receive(:list_workspaces_with_permission).and_return(%w[workspace-1 workspace-2])
          end

          it 'returns workspace IDs' do
            expect(user.inventory_groups).to eq(%w[workspace-1 workspace-2])
          end

          it 'calls KesselClient with correct parameters' do
            user.inventory_groups

            expect(KesselClient).to have_received(:list_workspaces_with_permission).with(
              permission: Rbac::INVENTORY_HOSTS_READ,
              user: user
            )
          end
        end

        context 'when user has no workspace access' do
          before do
            allow(KesselClient).to receive(:list_workspaces_with_permission).and_return([])
          end

          it 'returns empty array' do
            expect(user.inventory_groups).to eq([])
          end
        end

        context 'when KesselClient raises an error' do
          before do
            allow(KesselClient).to receive(:list_workspaces_with_permission).and_raise(
              KesselClient::AuthorizationError, 'Test error'
            )
            allow(Rails.logger).to receive(:error)
          end

          it 'returns empty array and logs error' do
            expect(user.inventory_groups).to eq([])
            expect(Rails.logger).to have_received(:error).with(/Kessel inventory groups failed/)
          end
        end
      end

      context 'when Kessel is disabled' do
        before do
          allow(KesselClient).to receive(:enabled?).and_return(false)
          allow(user).to receive(:rbac_permissions).and_return([])
          allow(Rbac).to receive(:load_inventory_groups).and_return(['group-1'])
        end

        it 'falls back to RBAC v1' do
          expect(user.inventory_groups).to eq(['group-1'])
          expect(Rbac).to have_received(:load_inventory_groups)
        end
      end

      context 'when RBAC is disabled globally' do
        before do
          allow(Settings).to receive(:disable_rbac).and_return(true)
        end

        it 'returns Rbac::ANY' do
          expect(user.inventory_groups).to eq(Rbac::ANY)
        end
      end

      context 'when user is cert authenticated' do
        before do
          allow(user).to receive(:cert_authenticated?).and_return(true)
        end

        it 'returns Rbac::ANY' do
          expect(user.inventory_groups).to eq(Rbac::ANY)
        end
      end
    end
  end
end
