# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'Kessel integration' do
    before do
      allow(KesselRbac).to receive(:enabled?).and_return(true)
    end

    describe '#v2_authorized_to?' do
      context 'when Kessel is enabled' do
        before do
          allow(KesselRbac).to receive(:enabled?).and_return(true)
        end

        context 'when user is authorized' do
          before do
            allow(KesselRbac).to receive(:default_permission_allowed?).and_return(true)
          end

          it 'returns true' do
            expect(user.kessel_authorized_to?(KesselRbac::POLICY_VIEW)).to be true
          end

          it 'calls KesselClient with correct parameters' do
            user.kessel_authorized_to?(KesselRbac::POLICY_VIEW)

            expect(KesselRbac).to have_received(:default_permission_allowed?).with(
              KesselRbac::POLICY_VIEW,
              user
            )
          end
        end

        context 'when user is not authorized' do
          before do
            allow(KesselRbac).to receive(:default_permission_allowed?).and_return(false)
          end

          it 'returns false' do
            expect(user.kessel_authorized_to?(KesselRbac::POLICY_VIEW)).to be false
          end
        end
      end

      context 'when Kessel is disabled' do
        before do
          allow(KesselRbac).to receive(:enabled?).and_return(false)
          allow(KesselRbac).to receive(:default_permission_allowed?)
        end

        it 'returns true (bypasses authorization)' do
          expect(user.kessel_authorized_to?(KesselRbac::POLICY_VIEW)).to be true
        end

        it 'does not call KesselClient' do
          user.kessel_authorized_to?(KesselRbac::POLICY_VIEW)
          expect(KesselRbac).not_to have_received(:default_permission_allowed?)
        end
      end
    end

    describe '#inventory_groups' do
      context 'when Kessel is enabled' do
        before do
          allow(KesselRbac).to receive(:enabled?).and_return(true)
        end

        context 'when user has workspace access' do
          before do
            allow(KesselRbac).to receive(:list_workspaces_with_permission).and_return(%w[workspace-1 workspace-2])
          end

          it 'returns workspace IDs' do
            expect(user.inventory_groups).to eq(%w[workspace-1 workspace-2])
          end

          it 'calls KesselClient with correct parameters' do
            user.inventory_groups

            expect(KesselRbac).to have_received(:list_workspaces_with_permission).with(
              permission: KesselRbac::SYSTEM_VIEW,
              user: user
            )
          end
        end

        context 'when user has no workspace access' do
          before do
            allow(KesselRbac).to receive(:list_workspaces_with_permission).and_return([])
          end

          it 'returns empty array' do
            expect(user.inventory_groups).to eq([])
          end
        end

        context 'when KesselClient raises an error' do
          before do
            allow(KesselRbac).to receive(:list_workspaces_with_permission).and_raise(
              KesselRbac::AuthorizationError, 'Test error'
            )
          end

          it 'propagates the error' do
            expect { user.inventory_groups }.to raise_error(KesselRbac::AuthorizationError, 'Test error')
          end
        end
      end

      context 'when Kessel is disabled' do
        before do
          allow(KesselRbac).to receive(:enabled?).and_return(false)
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
