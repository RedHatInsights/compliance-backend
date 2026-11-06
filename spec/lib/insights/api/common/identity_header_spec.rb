# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insights::Api::Common::IdentityHeader do
  subject(:header) { described_class.new(Base64.strict_encode64(payload.to_json)) }

  let(:cert_type) { 'satellite' }
  let(:payload) do
    {
      identity: {
        type: 'System',
        auth_type: described_class::CERT_AUTH,
        system: { cn: Faker::Internet.uuid, cert_type: cert_type }
      }
    }
  end

  describe '#cert_type' do
    it 'reads cert_type from the system identity' do
      expect(header.cert_type).to eq('satellite')
    end

    context 'when cert_type is absent' do
      let(:cert_type) { nil }

      it 'returns nil' do
        expect(header.cert_type).to be_nil
      end
    end
  end
end
