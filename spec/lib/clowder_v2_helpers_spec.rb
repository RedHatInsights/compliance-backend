# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClowderV2Helpers do
  before do
    allow(Settings).to receive_message_chain(:endpoints, :rbac, :url).and_return('http://rbac:8080')
    allow(Settings).to receive_message_chain(:endpoints, :rbac, :host).and_return('rbac:8080')
    allow(Settings).to receive_message_chain(:endpoints, :rbac, :scheme).and_return('http')
  end

  describe '.resolve_rbac_endpoint' do
    context 'when V2 endpoint is available with CA certificate' do
      before do
        v2_service = OpenStruct.new(
          url: 'http://rbac:8080',
          host: 'rbac:8080',
          scheme: 'http',
          ca_certificate: '/path/to/ca.crt',
          authenticated: false
        )
        allow(Settings).to receive_message_chain(:v2_endpoints, :rbac, :service).and_return(v2_service)
      end

      it 'resolves URL, host, scheme, CA, and authenticated from V2 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('http://rbac:8080')
        expect(result[:host]).to eq('rbac:8080')
        expect(result[:scheme]).to eq('http')
        expect(result[:ca_certificate]).to eq('/path/to/ca.crt')
        expect(result[:authenticated]).to be(false)
        expect(result[:source]).to eq(:v2)
      end
    end

    context 'when V2 endpoint has no CA certificate' do
      before do
        v2_service = OpenStruct.new(
          url: 'http://rbac:8080',
          host: 'rbac:8080',
          scheme: 'http',
          ca_certificate: nil,
          authenticated: false
        )
        allow(Settings).to receive_message_chain(:v2_endpoints, :rbac, :service).and_return(v2_service)
      end

      it 'returns nil ca_certificate for system trust' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('http://rbac:8080')
        expect(result[:ca_certificate]).to be_nil
        expect(result[:source]).to eq(:v2)
      end
    end

    context 'when V2 endpoint has HTTPS with authenticated flag' do
      before do
        v2_service = OpenStruct.new(
          url: 'https://rbac.example.com',
          host: 'rbac.example.com:443',
          scheme: 'https',
          ca_certificate: '/tls/service-ca.crt',
          authenticated: true
        )
        allow(Settings).to receive_message_chain(:v2_endpoints, :rbac, :service).and_return(v2_service)
      end

      it 'propagates scheme, CA certificate, and authenticated flag' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('https://rbac.example.com')
        expect(result[:host]).to eq('rbac.example.com:443')
        expect(result[:scheme]).to eq('https')
        expect(result[:ca_certificate]).to eq('/tls/service-ca.crt')
        expect(result[:authenticated]).to be(true)
        expect(result[:source]).to eq(:v2)
      end
    end

    context 'when V2 endpoints are not configured (nil)' do
      before do
        allow(Settings).to receive(:v2_endpoints).and_return(nil)
      end

      it 'falls back to V1 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:url]).to eq('http://rbac:8080')
        expect(result[:host]).to eq('rbac:8080')
        expect(result[:scheme]).to eq('http')
        expect(result[:ca_certificate]).to be_nil
        expect(result[:authenticated]).to be(false)
        expect(result[:source]).to eq(:v1)
      end
    end

    context 'when V2 endpoints exist but rbac is not present' do
      before do
        v2_endpoints = OpenStruct.new(rbac: nil)
        allow(Settings).to receive(:v2_endpoints).and_return(v2_endpoints)
      end

      it 'falls back to V1 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:source]).to eq(:v1)
        expect(result[:url]).to eq('http://rbac:8080')
      end
    end

    context 'when V2 rbac endpoint has no service deployment' do
      before do
        v2_endpoints = OpenStruct.new(rbac: OpenStruct.new(service: nil))
        allow(Settings).to receive(:v2_endpoints).and_return(v2_endpoints)
      end

      it 'falls back to V1 Settings' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:source]).to eq(:v1)
      end
    end

    context 'when Settings.v2_endpoints raises NoMethodError' do
      before do
        allow(Settings).to receive(:v2_endpoints).and_raise(NoMethodError)
      end

      it 'falls back to V1 Settings gracefully' do
        result = described_class.resolve_rbac_endpoint

        expect(result[:source]).to eq(:v1)
      end
    end
  end

  describe '.v2_settings' do
    context 'when V2 endpoint exists in Settings' do
      let(:v2_service) do
        OpenStruct.new(
          url: 'http://rbac:8080',
          host: 'rbac:8080',
          scheme: 'http',
          ca_certificate: '/path/to/ca.crt',
          authenticated: false
        )
      end

      before do
        allow(Settings).to receive_message_chain(:v2_endpoints, :rbac, :service).and_return(v2_service)
      end

      it 'returns the V2 service settings object' do
        result = described_class.v2_settings

        expect(result).not_to be_nil
        expect(result.url).to eq('http://rbac:8080')
        expect(result.ca_certificate).to eq('/path/to/ca.crt')
        expect(result.authenticated).to be(false)
      end
    end

    context 'when V2 endpoints are nil' do
      before do
        allow(Settings).to receive(:v2_endpoints).and_return(nil)
      end

      it 'returns nil' do
        expect(described_class.v2_settings).to be_nil
      end
    end

    context 'when Settings raises NoMethodError' do
      before do
        allow(Settings).to receive(:v2_endpoints).and_raise(NoMethodError)
      end

      it 'returns nil' do
        expect(described_class.v2_settings).to be_nil
      end
    end
  end
end
