# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClowderV2Helpers do
  let(:v2_endpoint_with_ca) do
    OpenStruct.new(
      uri: 'http://rbac:8080',
      ca_certificate: '/path/to/ca.crt',
      authenticated: false
    )
  end

  let(:v2_endpoint_no_ca) do
    OpenStruct.new(
      uri: 'http://rbac:8080',
      ca_certificate: '',
      authenticated: false
    )
  end

  let(:v2_endpoint_https) do
    OpenStruct.new(
      uri: 'https://rbac.example.com',
      ca_certificate: '/tls/service-ca.crt',
      authenticated: true
    )
  end

  let(:v2_endpoint_empty_uri) do
    OpenStruct.new(
      uri: '',
      ca_certificate: '',
      authenticated: false
    )
  end

  let(:v2_endpoints_hash) { { 'rbac' => { 'service' => v2_endpoint } } }
  let(:v2_endpoint) { v2_endpoint_with_ca }

  let(:clowder_config) do
    double('ClowderConfig', v2_dependency_endpoints: v2_endpoints_hash)
  end

  before do
    # Ensure Settings.endpoints.rbac is available for V1 fallback tests.
    # In test env, clowder-common-ruby engine populates these from test.json.
    allow(Settings).to receive_message_chain(:endpoints, :rbac, :url).and_return('http://rbac:8080')
    allow(Settings).to receive_message_chain(:endpoints, :rbac, :host).and_return('rbac:8080')
    allow(Settings).to receive_message_chain(:endpoints, :rbac, :scheme).and_return('http')
  end

  describe '.resolve_rbac_endpoint' do
    context 'when V2 endpoint is available with CA certificate' do
      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'resolves URL, host, scheme, and CA from V2 endpoint' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('http://rbac:8080')
        expect(result[:host]).to eq('rbac:8080')
        expect(result[:scheme]).to eq('http')
        expect(result[:ca_certificate]).to eq('/path/to/ca.crt')
        expect(result[:source]).to eq(:v2)
      end
    end

    context 'when V2 endpoint has no CA certificate' do
      let(:v2_endpoint) { v2_endpoint_no_ca }

      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'returns nil ca_certificate for system trust' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('http://rbac:8080')
        expect(result[:ca_certificate]).to be_nil
        expect(result[:source]).to eq(:v2)
      end
    end

    context 'when V2 endpoint has HTTPS URI with default port' do
      let(:v2_endpoint) { v2_endpoint_https }

      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'omits default port from host string' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('https://rbac.example.com')
        expect(result[:host]).to eq('rbac.example.com')
        expect(result[:scheme]).to eq('https')
        expect(result[:ca_certificate]).to eq('/tls/service-ca.crt')
        expect(result[:source]).to eq(:v2)
      end
    end

    context 'when V2 endpoint is absent (empty hash)' do
      let(:v2_endpoints_hash) { {} }

      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'falls back to V1 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('http://rbac:8080')
        expect(result[:host]).to eq('rbac:8080')
        expect(result[:scheme]).to eq('http')
        expect(result[:ca_certificate]).to be_nil
        expect(result[:source]).to eq(:v1)
      end
    end

    context 'when V2 endpoint has empty URI' do
      let(:v2_endpoint) { v2_endpoint_empty_uri }

      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'falls back to V1 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:source]).to eq(:v1)
        expect(result[:url]).to eq('http://rbac:8080')
      end
    end

    context 'when v2_dependency_endpoints is nil' do
      let(:clowder_config) do
        double('ClowderConfig', v2_dependency_endpoints: nil)
      end

      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'falls back to V1 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:source]).to eq(:v1)
      end
    end

    context 'when Clowder is not enabled' do
      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(false)
      end

      it 'falls back to V1 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:source]).to eq(:v1)
        expect(result[:host]).to eq('rbac:8080')
      end
    end

    context 'when Config.load raises an error' do
      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_raise(StandardError, 'config unavailable')
      end

      it 'falls back to V1 Settings gracefully' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:source]).to eq(:v1)
      end
    end
  end

  describe '.v2_endpoint' do
    context 'when Clowder is enabled and endpoint exists' do
      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'returns the DependencyEndpointV2 object' do
        result = described_class.v2_endpoint('rbac', 'service')

        expect(result).not_to be_nil
        expect(result.uri).to eq('http://rbac:8080')
        expect(result.ca_certificate).to eq('/path/to/ca.crt')
        expect(result.authenticated).to be(false)
      end
    end

    context 'when endpoint key does not match' do
      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(true)
        allow(ClowderCommonRuby::Config).to receive(:load).and_return(clowder_config)
      end

      it 'returns nil for unknown app key' do
        expect(described_class.v2_endpoint('unknown', 'service')).to be_nil
      end

      it 'returns nil for unknown deployment key' do
        expect(described_class.v2_endpoint('rbac', 'unknown')).to be_nil
      end
    end

    context 'when Clowder is not enabled' do
      before do
        allow(ClowderCommonRuby::Config).to receive(:clowder_enabled?).and_return(false)
      end

      it 'returns nil without attempting Config.load' do
        expect(ClowderCommonRuby::Config).not_to receive(:load)
        expect(described_class.v2_endpoint('rbac', 'service')).to be_nil
      end
    end
  end
end
