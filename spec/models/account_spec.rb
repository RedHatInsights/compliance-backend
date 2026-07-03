# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  subject(:account) { build(:account) }

  describe '.from_identity_header' do
    subject(:result) { described_class.from_identity_header(identity_header) }

    let(:identity_header) do
      Insights::Api::Common::IdentityHeader.new(
        Base64.encode64({ identity: { org_id: Faker::Number.number(digits: 7).to_s } }.to_json)
      )
    end

    it 'finds or creates an account by org_id' do
      expect { result }.to change(described_class, :count).by(1)
      expect(result.org_id).to eq(identity_header.identity['org_id'])
    end

    it 'sets the identity_header on the account' do
      expect(result.identity_header).to eq(identity_header)
    end

    it 'does not create a duplicate on second call' do
      described_class.from_identity_header(identity_header)
      expect { result }.not_to change(described_class, :count)
    end
  end

  describe '#b64_identity' do
    subject(:account) { build(:account, org_id: Faker::Number.number(digits: 7).to_s) }

    it 'returns a base64-encoded JSON identity' do
      decoded = JSON.parse(Base64.strict_decode64(account.b64_identity))
      expect(decoded.dig('identity', 'org_id')).to eq(account.org_id)
    end
  end
end
