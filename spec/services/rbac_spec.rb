# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rbac do
  let(:user) { FactoryBot.create(:user) }
  let(:identity) { user.account.identity_header.raw }

  after do
    described_class.rbac_authenticated = nil
  end

  describe '.load_user_permissions' do
    let(:mock_access) do
      RBACApiClient::Access.new(
        permission: Rbac::COMPLIANCE_VIEWER,
        resource_definitions: []
      )
    end
    let(:mock_response) { double('response', data: [mock_access]) }

    context 'when rbac_authenticated is false' do
      before do
        described_class.rbac_authenticated = false
        allow(Rbac::API_CLIENT).to receive(:get_principal_access).and_return(mock_response)
      end

      it 'sends only X-RH-IDENTITY with debug auth names disabled' do
        described_class.load_user_permissions(identity)

        expect(Rbac::API_CLIENT).to have_received(:get_principal_access) do |apps, opts|
          expect(apps).to eq(Rbac::APPS)
          expect(opts[:header_params]).to eq('X-RH-IDENTITY': identity)
          expect(opts[:debug_auth_names]).to eq([])
        end
      end

      it 'does not request a service token' do
        expect(KesselBuilder).not_to receive(:auth)

        described_class.load_user_permissions(identity)

        expect(Rbac::API_CLIENT).to have_received(:get_principal_access) do |_apps, opts|
          expect(opts[:debug_auth_names]).to eq([])
        end
      end
    end

    context 'when rbac_authenticated is true' do
      let(:mock_token) { double('token', access_token: 'test-bearer-token') }
      let(:mock_auth) { double('oauth_credentials', get_token: mock_token) }

      before do
        described_class.rbac_authenticated = true
        allow(KesselBuilder).to receive(:auth).and_return(mock_auth)
        allow(Rbac::API_CLIENT).to receive(:get_principal_access).and_return(mock_response)
      end

      it 'includes X-RH-IDENTITY and Bearer token headers' do
        described_class.load_user_permissions(identity)

        expect(Rbac::API_CLIENT).to have_received(:get_principal_access) do |_apps, opts|
          headers = opts[:header_params]
          expect(headers).to eq(
            'X-RH-IDENTITY': identity,
            Authorization: 'Bearer test-bearer-token'
          )
          expect(opts[:debug_auth_names]).to eq([])
        end
      end

      it 'obtains the token from KesselBuilder.auth' do
        described_class.load_user_permissions(identity)
        expect(KesselBuilder).to have_received(:auth)
      end

      it 'does not call RBAC when token acquisition fails' do
        allow(mock_auth).to receive(:get_token).and_raise(StandardError, 'token failure')

        expect(Rbac::API_CLIENT).not_to receive(:get_principal_access)
        expect { described_class.load_user_permissions(identity) }.to raise_error(StandardError, 'token failure')
      end
    end
  end
end
