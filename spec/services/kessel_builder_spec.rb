# frozen_string_literal: true

require 'rails_helper'
require 'kessel-sdk'

RSpec.describe KesselBuilder, type: :service do
  describe '.build_client' do
    let(:mock_builder) { double('client_builder') }
    let(:mock_client) { double('kessel_client') }

    before do
      allow(Kessel::Inventory::V1beta2::KesselInventoryService::ClientBuilder).to receive(:new).and_return(mock_builder)
      allow(mock_builder).to receive(:insecure).and_return(mock_builder)
      allow(mock_builder).to receive(:authenticated).and_return(mock_builder)
      allow(mock_builder).to receive(:oauth2_client_authenticated).and_return(mock_builder)
      allow(mock_builder).to receive(:build).and_return(mock_client)
    end

    context 'when using insecure connection' do
      before { allow(Settings.kessel).to receive(:insecure).and_return(true) }

      it 'builds insecure client' do
        result = described_class.build_client
        expect(result).to eq(mock_client)
        expect(mock_builder).to have_received(:insecure)
        expect(mock_builder).to have_received(:build)
      end
    end

    context 'when using secure connection' do
      before do
        allow(Settings.kessel).to receive(:insecure).and_return(false)
        allow(Settings.kessel.auth).to receive(:enabled).and_return(false)
      end

      it 'builds secure client without OAuth' do
        result = described_class.build_client
        expect(result).to eq(mock_client)
        expect(mock_builder).to have_received(:authenticated)
        expect(mock_builder).to have_received(:build)
      end
    end

    context 'when using secure connection with OAuth' do
      let(:mock_auth) { double('oauth_credentials') }

      before do
        allow(Settings.kessel).to receive(:insecure).and_return(false)
        allow(Settings.kessel.auth).to receive(:enabled).and_return(true)
        allow(described_class).to receive(:build_oauth_credentials).and_return(mock_auth)
      end

      it 'builds secure client with OAuth' do
        result = described_class.build_client
        expect(result).to eq(mock_client)
        expect(mock_builder).to have_received(:oauth2_client_authenticated).with(mock_auth)
        expect(mock_builder).to have_received(:build)
      end
    end

    context 'when client building fails' do
      before do
        allow(mock_builder).to receive(:build).and_raise(StandardError, 'Connection failed')
        allow(Rails.logger).to receive(:error)
      end

      it 'raises ConfigurationError and logs error' do
        expect do
          described_class.build_client
        end.to raise_error(KesselBuilder::ConfigurationError, /Failed to build Kessel client/)
        expect(Rails.logger).to have_received(:error).with(/Failed to build Kessel client/)
      end
    end
  end

  describe '.build_oauth_credentials' do
    let(:mock_discovery) { double('discovery', token_endpoint: 'https://example.com/token') }
    let(:mock_credentials) { double('oauth_credentials') }

    before do
      allow(described_class).to receive(:fetch_oidc_discovery).and_return(mock_discovery)
      allow(described_class).to receive(:new_oauth_credentials_with_token_endpoint).and_return(mock_credentials)
    end

    it 'fetches OIDC discovery and creates credentials' do
      result = described_class.build_oauth_credentials
      expect(result).to eq(mock_credentials)
      expect(described_class).to have_received(:new_oauth_credentials_with_token_endpoint).with('https://example.com/token')
    end
  end

  describe '.new_oauth_credentials_with_token_endpoint' do
    let(:token_endpoint) { 'https://example.com/token' }
    let(:mock_credentials) { double('oauth_credentials') }

    before do
      allow(Settings.kessel.auth).to receive(:client_id).and_return('test-client-id')
      allow(Settings.kessel.auth).to receive(:client_secret).and_return('test-client-secret')
      stub_const('OAuth2ClientCredentials', Class.new)
      allow(Kessel::Auth::OAuth2ClientCredentials).to receive(:new).and_return(mock_credentials)
    end

    it 'creates OAuth credentials with token endpoint' do
      result = described_class.new_oauth_credentials_with_token_endpoint(token_endpoint)
      expect(result).to eq(mock_credentials)
      expect(Kessel::Auth::OAuth2ClientCredentials).to have_received(:new).with(
        client_id: 'test-client-id',
        client_secret: 'test-client-secret',
        token_endpoint: token_endpoint
      )
    end
  end
end
