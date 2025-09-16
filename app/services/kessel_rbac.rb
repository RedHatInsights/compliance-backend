# frozen_string_literal: true

require 'kessel-sdk'
require 'kessel/inventory/v1beta2/inventory_service_services_pb'

# rubocop:disable Metrics/ClassLength

# Service for interacting with Kessel for RBAC v2 authorization
class KesselRbac
  class AuthorizationError < StandardError; end
  class ConfigurationError < StandardError; end

  POLICY_VIEW = 'compliance_policy_view'
  POLICY_NEW = 'compliance_policy_new'
  POLICY_EDIT = 'compliance_policy_edit'
  POLICY_REMOVE = 'compliance_policy_remove'
  SYSTEM_VIEW = 'compliance_system_view'
  REPORT_VIEW = 'compliance_report_view'
  REPORT_REMOVE = 'compliance_report_remove'
  SECURITY_GUIDE_VIEW = 'compliance_securityguide_view'

  class << self
    def enabled?
      ActiveModel::Type::Boolean.new.cast(Settings.kessel.enabled)
    end

    def client
      @client ||= build_client
    end

    def auth
      @auth ||= build_oauth_credentials
    end

    include Kessel::Inventory::V1beta2
    include Kessel::GRPC
    include Kessel::Auth

    # rubocop:disable Metrics/MethodLength
    def default_permission_allowed?(permission, user)
      return false unless permission

      default_workspace_id = get_default_workspace_id(auth, Settings.endpoints.rbac.url,
                                                      user.account.identity_header.raw)

      check_permission(
        resource_type: 'workspace',
        resource_id: default_workspace_id,
        permission: permission,
        user: user,
        use_check_for_update: permission.include?('write') || permission.include?('delete')
      )
    rescue AuthorizationError => e
      Rails.logger.error("Kessel RBAC check failed: #{e.message}")
      false
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/ParameterLists
    def check_permission(resource_type:, resource_id:, permission:, user:, use_check_for_update: false,
                         reporter_type: 'rbac')
      return true unless enabled?

      object = build_resource_reference(resource_type, resource_id, reporter_type)
      subject = build_subject_reference(user)

      request_class = use_check_for_update ? CheckForUpdateRequest : CheckRequest
      request = request_class.new(
        object: object,
        relation: permission,
        subject: subject
      )

      begin
        method = use_check_for_update ? :check_for_update : :check
        response = client.public_send(method, request)
        response.allowed
      rescue StandardError => e
        Rails.logger.error("Kessel authorization check failed: #{e.message}")
        raise AuthorizationError, "Authorization check failed: #{e.message}"
      end
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def list_workspaces_with_permission(permission:, user:)
      return [] unless enabled?

      object_type = RepresentationType.new(
        resource_type: 'workspace',
        reporter_type: 'rbac'
      )
      subject = build_subject_reference(user)

      request = StreamedListObjectsRequest.new(
        object_type: object_type,
        relation: permission,
        subject: subject
      )

      begin
        response = client.streamed_list_objects(request)

        response.map(&:object).map(&:resource_id)
      rescue StandardError => e
        Rails.logger.error("Kessel workspace listing failed: #{e.message}")
        raise AuthorizationError, "Workspace listing failed: #{e.message}"
      end
    end
    # rubocop:enable Metrics/MethodLength

    delegate :get_default_workspace_id, to: :KesselUtils

    private

    def build_client
      raise ConfigurationError, 'Kessel is not enabled' unless enabled?

      # Create gRPC client using the actual Kessel SDK API
      if Settings.kessel.insecure
        build_insecure_client
      else
        build_secure_client
      end
    rescue StandardError => e
      Rails.logger.error("Failed to build Kessel client: #{e.message}")
      raise ConfigurationError, "Failed to build Kessel client: #{e.message}"
    end

    def build_insecure_client
      KesselInventoryService::ClientBuilder.new(Settings.kessel.url).insecure.build
    end

    def build_secure_client
      builder = KesselInventoryService::ClientBuilder.new(Settings.kessel.url)

      if Settings.kessel.auth.enabled
        builder.oauth2_client_authenticated(auth)
      else
        builder.authenticated
      end

      builder.build
    end

    # rubocop:disable Metrics/AbcSize
    def build_oauth_credentials
      # Fetch OIDC discovery metadata
      discovery = fetch_oidc_discovery(Settings.kessel.auth.oidc_issuer)

      # Create OAuth2 client credentials
      OAuth2ClientCredentials.new(
        client_id: Settings.kessel.auth.client_id,
        client_secret: Settings.kessel.auth.client_secret,
        token_endpoint: discovery.token_endpoint
      )
    rescue StandardError => e
      Rails.logger.error("Failed to build OAuth credentials: #{e.message}")
      raise ConfigurationError, "Failed to build OAuth credentials: #{e.message}"
    end
    # rubocop:enable Metrics/AbcSize

    def build_resource_reference(resource_type, resource_id, reporter_type)
      ResourceReference.new(
        resource_type: resource_type,
        resource_id: resource_id,
        reporter: ReporterReference.new(type: reporter_type)
      )
    end

    # rubocop:disable Metrics/MethodLength
    def build_subject_reference(user)
      identity = user.account.identity_header.identity

      identity_type = identity&.dig('type')

      principal_id = if identity_type == 'ServiceAccount'
                       identity&.dig('service_account', 'user_id')
                     elsif identity_type == 'User'
                       identity&.dig('user', 'user_id')
                     else
                       raise 'unsupported identity type'
                     end

      SubjectReference.new(
        resource: ResourceReference.new(
          resource_type: 'principal',
          resource_id: "redhat/#{principal_id}",
          reporter: ReporterReference.new(type: 'rbac')
        )
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end

# rubocop:enable Metrics/ClassLength
# Utilities used by Kessel
class KesselUtils
  class << self
    def get_default_workspace_id(auth, rbac_base_endpoint, identity_header)
      parsed_identity = Insights::Api::Common::IdentityHeader.new(identity_header)
      org_id = parsed_identity.org_id
      cache_key = "workspace_default_#{org_id}"

      return @workspace_cache[cache_key] if @workspace_cache&.key?(cache_key)

      workspace_id = fetch_default_workspace(auth, rbac_base_endpoint, org_id)
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
