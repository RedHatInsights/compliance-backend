# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rbac do
  let(:user) { FactoryBot.create(:user) }
  let(:identity) { user.account.identity_header.raw }

  describe '.load_user_permissions' do
    let(:mock_access) do
      RBACApiClient::Access.new(
        permission: Rbac::COMPLIANCE_VIEWER,
        resource_definitions: []
      )
    end
    let(:mock_response) { double('response', data: [mock_access]) }

    before do
      allow(Settings.v2_endpoints.rbac.service).to receive(:authenticated).and_return(authenticated)
      allow(Rbac::API_CLIENT).to receive(:get_principal_access).and_return(mock_response)
    end

    context 'when the V2 endpoint is not authenticated' do
      let(:authenticated) { false }

      it 'sends only X-RH-IDENTITY with generated auth disabled' do
        expect(KesselBuilder).not_to receive(:bearer_header)

        expect(described_class.load_user_permissions(identity)).to eq([mock_access])
        expect(Rbac::API_CLIENT).to have_received(:get_principal_access) do |apps, opts|
          expect(apps).to eq(Rbac::APPS)
          expect(opts[:header_params]).to eq('X-RH-IDENTITY': identity)
          expect(opts[:debug_auth_names]).to eq([])
        end
      end
    end

    context 'when the V2 endpoint is authenticated' do
      let(:authenticated) { true }
      let(:bearer) { { Authorization: "Bearer #{Faker::Alphanumeric.alphanumeric(number: 32)}" } }

      it 'sends X-RH-IDENTITY and the bearer' do
        allow(KesselBuilder).to receive(:bearer_header).and_return(bearer)

        described_class.load_user_permissions(identity)

        expect(Rbac::API_CLIENT).to have_received(:get_principal_access) do |_apps, opts|
          expect(opts[:header_params]).to eq({ 'X-RH-IDENTITY': identity }.merge(bearer))
          expect(opts[:debug_auth_names]).to eq([])
        end
      end

      it 'does not call RBAC when the token cannot be fetched' do
        allow(KesselBuilder).to receive(:bearer_header).and_raise(KesselBuilder::TokenError)

        expect { described_class.load_user_permissions(identity) }.to raise_error(KesselBuilder::TokenError)
        expect(Rbac::API_CLIENT).not_to have_received(:get_principal_access)
      end
    end
  end
end
