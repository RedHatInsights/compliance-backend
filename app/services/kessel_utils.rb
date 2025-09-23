# frozen_string_literal: true

# Utilities used by Kessel
class KesselUtils
  class << self
    def get_default_workspace_id(auth, identity_header)
      parsed_identity = Insights::Api::Common::IdentityHeader.new(identity_header)
      org_id = parsed_identity.org_id
      cache_key = "workspace_default_#{org_id}"

      return @workspace_cache[cache_key] if @workspace_cache&.key?(cache_key)

      workspace_id = fetch_default_workspace(auth, Settings.endpoints.rbac.url, org_id)
      @workspace_cache ||= {}
      @workspace_cache[cache_key] = workspace_id

      workspace_id
    end

    private

    def fetch_default_workspace(auth, rbac_base_endpoint, org_id)
      access_token = auth.get_token.access_token

      workspace_response = make_workspace_request(rbac_base_endpoint, access_token, org_id)
      workspace_id = extract_workspace_id(workspace_response)

      raise "No default workspace found for org id: #{org_id}" unless workspace_id

      workspace_id
    end

    def make_workspace_request(rbac_base_endpoint, access_token, org_id)
      conn = build_faraday_connection(rbac_base_endpoint)

      conn.get('/api/rbac/v2/workspaces/') do |req|
        req.params['type'] = 'default'
        req.headers['authorization'] = "Bearer #{access_token}"
        req.headers['x-rh-rbac-org-id'] = org_id
        req.headers['Content-Type'] = 'application/json'
      end
    end

    def build_faraday_connection(rbac_base_endpoint)
      Faraday.new(url: rbac_base_endpoint) do |f|
        f.request :url_encoded
        f.response :json
        f.adapter Faraday.default_adapter
        # Do we need to add ENV['SSL_CERT_FILE'] ?
      end
    end

    def extract_workspace_id(response)
      raise "RBAC API error: #{response.status} - #{response.body}" unless response.success?

      workspaces = response.body
      workspace = workspaces.dig('data')&.first
      return workspace['id'] if workspace&.dig('id')

      nil
    end
  end
end
