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

      it 'sends only X-RH-IDENTITY header' do
        described_class.load_user_permissions(identity)

        expect(Rbac::API_CLIENT).to have_received(:get_principal_access).with(
          Rbac::APPS,
          hash_including(header_params: hash_including('X-RH-IDENTITY': identity))
        )
      end

      it 'does not include Authorization header' do
        described_class.load_user_permissions(identity)

        expect(Rbac::API_CLIENT).to have_received(:get_principal_access) do |_apps, opts|
          expect(opts[:header_params]).not_to have_key(:Authorization)
          expect(opts[:header_params]).not_to have_key(:'X-RH-RBAC-ORG-ID')
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

      it 'includes Bearer token and org_id headers' do
        described_class.load_user_permissions(identity)

        expect(Rbac::API_CLIENT).to have_received(:get_principal_access) do |_apps, opts|
          headers = opts[:header_params]
          expect(headers[:'X-RH-IDENTITY']).to eq(identity)
          expect(headers[:Authorization]).to eq('Bearer test-bearer-token')
          expect(headers[:'X-RH-RBAC-ORG-ID']).to eq(user.account.org_id)
        end
      end

      it 'obtains the token from KesselBuilder.auth' do
        described_class.load_user_permissions(identity)
        expect(KesselBuilder).to have_received(:auth)
      end
    end
  end
end
