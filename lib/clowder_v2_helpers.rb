# frozen_string_literal: true

require 'uri'

# Resolves dependency endpoints using Clowder V2 DependencyEndpoint API
# with fallback to V1 flat endpoints via Settings.
#
# V2 endpoints provide a full URI, CA certificate path, and auth flag.
# V1 endpoints are populated into Settings by the clowder-common-ruby engine
# from the flat `endpoints[]` array in the ACG config.
module ClowderV2Helpers
  module_function

  # Resolve the RBAC endpoint using V2 DependencyEndpoint if available,
  # falling back to V1 Settings.endpoints.rbac.
  #
  # @return [Hash] with keys :url, :host, :scheme, :ca_certificate, :authenticated, :source
  def resolve_rbac_endpoint
    v2 = v2_endpoint('rbac', 'service')
    v2&.uri.present? ? v2_rbac_result(v2) : v1_rbac_result
  rescue URI::InvalidURIError
    v1_rbac_result
  end

  # Build result hash from a V2 DependencyEndpoint.
  #
  # @param endpoint [OpenStruct] V2 endpoint with .uri, .ca_certificate
  # @return [Hash]
  def v2_rbac_result(endpoint)
    uri = URI.parse(endpoint.uri)
    {
      url: endpoint.uri,
      host: host_with_port(uri),
      scheme: uri.scheme,
      ca_certificate: endpoint.ca_certificate.presence,
      authenticated: endpoint.authenticated == true,
      source: :v2
    }
  end

  # Build result hash from V1 Settings populated by the clowder engine.
  #
  # @return [Hash]
  def v1_rbac_result
    {
      url: Settings.endpoints.rbac.url,
      host: Settings.endpoints.rbac.host,
      scheme: Settings.endpoints.rbac.scheme,
      ca_certificate: nil,
      authenticated: false,
      source: :v1
    }
  end

  # Format host string, omitting default ports (80/443).
  #
  # @param uri [URI] parsed URI
  # @return [String]
  def host_with_port(uri)
    uri.port == uri.default_port ? uri.host : "#{uri.host}:#{uri.port}"
  end

  # Look up a V2 DependencyEndpoint from the Clowder ACG config.
  #
  # @param app_key [String] the dependency app name (e.g. "rbac")
  # @param deployment_key [String] the deployment name (e.g. "service")
  # @return [OpenStruct, nil] DependencyEndpointV2 with .uri, .ca_certificate, .authenticated
  def v2_endpoint(app_key, deployment_key)
    return nil unless defined?(ClowderCommonRuby) && ClowderCommonRuby::Config.clowder_enabled?

    ClowderCommonRuby::Config.load.v2_dependency_endpoints&.dig(app_key, deployment_key)
  rescue StandardError
    nil
  end
end
