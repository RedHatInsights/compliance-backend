# frozen_string_literal: true

require 'kessel-sdk'

# Utilities used by Kessel
class KesselUtils
  WORKSPACE_CACHE_PREFIX = 'compliance/kessel/workspace_default'
  WORKSPACE_CACHE_EXPIRY = 1.day

  class << self
    include Kessel::RBAC::V2
    include Kessel::Auth

    def get_default_workspace_id(auth, identity_header)
      parsed_identity = Insights::Api::Common::IdentityHeader.new(identity_header)
      org_id = parsed_identity.org_id

      Rails.cache.fetch(workspace_cache_key(org_id), expires_in: WORKSPACE_CACHE_EXPIRY) do
        fetch_workspace_id(auth, org_id)
      end
    end

    private

    def workspace_cache_key(org_id)
      "#{WORKSPACE_CACHE_PREFIX}/#{org_id}"
    end

    def fetch_workspace_id(auth, org_id)
      fetch_default_workspace(
        Settings.endpoints.rbac.url,
        org_id,
        auth: oauth2_auth_request(auth),
        http_client: nil
      ).id
    end
  end
end
