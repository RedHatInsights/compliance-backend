# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KesselUtils, type: :service do
  let(:user) { create(:user) }
  let(:auth) { double('oauth_credentials') }
  let(:workspace_id) { "default-workspace-#{user.org_id}" }
  let(:cache_key) { "#{described_class::WORKSPACE_CACHE_PREFIX}/#{user.org_id}" }
  let(:identity_header) { user.account.identity_header.raw }

  before do
    allow(described_class).to receive(:oauth2_auth_request).with(auth).and_return(auth)
  end

  it 'uses an expiring Rails cache entry scoped to organization' do
    expect(Rails.cache).to receive(:fetch)
      .with(cache_key, expires_in: described_class::WORKSPACE_CACHE_EXPIRY)
      .and_yield
    expect(described_class).to receive(:fetch_default_workspace).with(
      Settings.endpoints.rbac.url,
      user.org_id,
      auth: auth,
      http_client: nil
    ).and_return(double('workspace', id: workspace_id))

    expect(described_class.get_default_workspace_id(auth, identity_header)).to eq(workspace_id)
  end

  it 'returns cached workspace ID without querying Kessel' do
    expect(Rails.cache).to receive(:fetch)
      .with(cache_key, expires_in: described_class::WORKSPACE_CACHE_EXPIRY)
      .and_return(workspace_id)
    expect(described_class).not_to receive(:fetch_default_workspace)

    expect(described_class.get_default_workspace_id(auth, identity_header)).to eq(workspace_id)
  end
end
