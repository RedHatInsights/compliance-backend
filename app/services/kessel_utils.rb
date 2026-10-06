# frozen_string_literal: true

require 'kessel-sdk'

# Utilities used by Kessel
class KesselUtils
  class << self
    include Kessel::RBAC::V2
    include Kessel::Auth

    def get_default_workspace_id(auth, identity_header)
      parsed_identity = Insights::Api::Common::IdentityHeader.new(identity_header)
      org_id = parsed_identity.org_id
      cache_key = "workspace_default_#{org_id}"

      return @workspace_cache[cache_key] if @workspace_cache&.key?(cache_key)

      workspace = fetch_default_workspace(rbac_url, org_id, auth: oauth2_auth_request(auth),
                                                            http_client: nil)
      @workspace_cache ||= {}
      @workspace_cache[cache_key] = workspace.id

      workspace.id
    end

    private

    # Memoized RBAC URL resolved via V2 DependencyEndpoint with V1 fallback.
    # The endpoint is fixed at pod startup, so caching is safe.
    def rbac_url
      @rbac_url ||= ClowderV2Helpers.resolve_rbac_endpoint[:url]
    end
  end
end
