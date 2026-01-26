# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KesselUtils, type: :service do
  let(:user) { create(:v2_user) }
  let(:org_id) { user.org_id }
  let(:identity_header) { user.account.identity_header.raw }
  let(:auth) { double('oauth_credentials') }
  let(:mock_workspace) { double('workspace', id: 'test-workspace-id') }

  before do
    # Clear the cache before each test
    described_class.instance_variable_set(:@workspace_cache, nil)
  end

  describe '.get_default_workspace_id' do
    before do
      allow(described_class).to receive(:fetch_default_workspace).and_return(mock_workspace)
      allow(described_class).to receive(:oauth2_auth_request).and_return(auth)
    end

    it 'fetches and returns the default workspace id' do
      result = described_class.get_default_workspace_id(auth, identity_header)

      expect(result).to eq('test-workspace-id')
      expect(described_class).to have_received(:fetch_default_workspace).with(
        Settings.endpoints.rbac.url,
        org_id,
        auth: auth,
        http_client: nil
      )
    end

    it 'caches the workspace id for subsequent calls' do
      # First call
      first_result = described_class.get_default_workspace_id(auth, identity_header)
      expect(first_result).to eq('test-workspace-id')

      # Second call should use cache
      second_result = described_class.get_default_workspace_id(auth, identity_header)
      expect(second_result).to eq('test-workspace-id')

      # Should only fetch once due to caching
      expect(described_class).to have_received(:fetch_default_workspace).once
    end

    it 'stores cache with correct key format' do
      described_class.get_default_workspace_id(auth, identity_header)

      cache = described_class.instance_variable_get(:@workspace_cache)
      expect(cache).to have_key("workspace_default_#{org_id}")
      expect(cache["workspace_default_#{org_id}"]).to eq('test-workspace-id')
    end
  end

  describe '.get_root_workspace_id' do
    before do
      allow(described_class).to receive(:fetch_root_workspace).and_return(mock_workspace)
      allow(described_class).to receive(:oauth2_auth_request).and_return(auth)
    end

    it 'fetches and returns the root workspace id' do
      result = described_class.get_root_workspace_id(auth, identity_header)

      expect(result).to eq('test-workspace-id')
      expect(described_class).to have_received(:fetch_root_workspace).with(
        Settings.endpoints.rbac.url,
        org_id,
        auth: auth,
        http_client: nil
      )
    end

    it 'caches the workspace id for subsequent calls' do
      # First call
      first_result = described_class.get_root_workspace_id(auth, identity_header)
      expect(first_result).to eq('test-workspace-id')

      # Second call should use cache
      second_result = described_class.get_root_workspace_id(auth, identity_header)
      expect(second_result).to eq('test-workspace-id')

      # Should only fetch once due to caching
      expect(described_class).to have_received(:fetch_root_workspace).once
    end

    it 'stores cache with correct key format' do
      described_class.get_root_workspace_id(auth, identity_header)

      cache = described_class.instance_variable_get(:@workspace_cache)
      expect(cache).to have_key("workspace_root_#{org_id}")
      expect(cache["workspace_root_#{org_id}"]).to eq('test-workspace-id')
    end

    it 'uses separate cache from default workspace' do
      allow(described_class).to receive(:fetch_default_workspace).and_return(
        double('default_workspace', id: 'default-workspace-id')
      )
      allow(described_class).to receive(:fetch_root_workspace).and_return(
        double('root_workspace', id: 'root-workspace-id')
      )

      default_id = described_class.get_default_workspace_id(auth, identity_header)
      root_id = described_class.get_root_workspace_id(auth, identity_header)

      expect(default_id).to eq('default-workspace-id')
      expect(root_id).to eq('root-workspace-id')

      cache = described_class.instance_variable_get(:@workspace_cache)
      expect(cache["workspace_default_#{org_id}"]).to eq('default-workspace-id')
      expect(cache["workspace_root_#{org_id}"]).to eq('root-workspace-id')
    end
  end

  describe 'cache isolation between orgs' do
    let(:user2) { create(:v2_user) }
    let(:org_id2) { user2.org_id }
    let(:identity_header2) { user2.account.identity_header.raw }
    let(:mock_workspace2) { double('workspace2', id: 'org2-workspace-id') }

    before do
      allow(described_class).to receive(:fetch_root_workspace).and_return(mock_workspace, mock_workspace2)
      allow(described_class).to receive(:oauth2_auth_request).and_return(auth)
    end

    it 'maintains separate cache entries for different orgs' do
      result1 = described_class.get_root_workspace_id(auth, identity_header)
      result2 = described_class.get_root_workspace_id(auth, identity_header2)

      expect(result1).to eq('test-workspace-id')
      expect(result2).to eq('org2-workspace-id')

      cache = described_class.instance_variable_get(:@workspace_cache)
      expect(cache["workspace_root_#{org_id}"]).to eq('test-workspace-id')
      expect(cache["workspace_root_#{org_id2}"]).to eq('org2-workspace-id')
    end
  end
end
