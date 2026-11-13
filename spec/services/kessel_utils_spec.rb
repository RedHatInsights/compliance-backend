# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KesselUtils do
  describe '.get_default_workspace_id' do
    let(:org_id) { Faker::Number.number(digits: 7).to_s }
    let(:identity_header) { Base64.strict_encode64({ identity: { org_id: org_id } }.to_json) }
    let(:workspace_id) { SecureRandom.uuid }
    let(:auth) { double('oauth_credentials') }
    let(:auth_request) { double('auth_request') }

    before do
      described_class.instance_variable_set(:@workspace_cache, nil)
      allow(described_class).to receive(:oauth2_auth_request).with(auth).and_return(auth_request)
      allow(described_class).to receive(:fetch_default_workspace)
        .and_return(double('workspace', id: workspace_id))
    end

    it 'fetches the workspace from the V2 RBAC endpoint and caches it' do
      2.times { expect(described_class.get_default_workspace_id(auth, identity_header)).to eq(workspace_id) }

      expect(described_class).to have_received(:fetch_default_workspace).once.with(
        Settings.v2_endpoints.rbac.service.url, org_id, auth: auth_request, http_client: nil
      )
    end
  end
end
