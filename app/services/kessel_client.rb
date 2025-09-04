# frozen_string_literal: true

require 'kessel-sdk'
require 'kessel/inventory/v1beta2/inventory_service_services_pb'

# Service for interacting with Kessel for RBAC v2 authorization
class KesselClient
  class AuthorizationError < StandardError; end
  class ConfigurationError < StandardError; end

  # Permission mappings from RBAC v1 to Kessel compound permissions
  PERMISSION_MAPPINGS = {
    # Compliance permissions
    'compliance:policy:read' => 'compliance_policy_view',
    'compliance:policy:create' => 'compliance_policy_create',
    'compliance:policy:write' => 'compliance_policy_edit',
    'compliance:policy:delete' => 'compliance_policy_delete',
    'compliance:report:read' => 'compliance_report_view',
    'compliance:system:read' => 'compliance_system_view',
    'compliance:*:read' => 'compliance_all_read',

    # Inventory permissions
    'inventory:hosts:read' => 'inventory_host_view'
  }.freeze

  class << self
    def enabled?
      ActiveModel::Type::Boolean.new.cast(Settings.kessel.enabled)
    end

    def client
      @client ||= build_client
    end

    include Kessel::Inventory::V1beta2
    include Kessel::GRPC
    include Kessel::Auth

    # Check if user has permission on a resource
    # @param resource_type [String] Type of resource (e.g., 'workspace', 'system')
    # @param resource_id [String] ID of the resource
    # @param permission [String] Permission to check
    # @param user [User] User to check permission for
    # @param use_check_for_update [Boolean] Whether to use CheckForUpdate (for writes/sensitive reads)
    # @return [Boolean] Whether user has permission
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/ParameterLists
    def check_permission(resource_type:, resource_id:, permission:, user:, use_check_for_update: false,
                         reporter_type: 'rbac')
      return true unless enabled?

      kessel_permission = map_permission(permission)

      object = build_resource_reference(resource_type, resource_id, reporter_type)
      subject = build_subject_reference(user)

      request_class = use_check_for_update ? CheckForUpdateRequest : CheckRequest
      request = request_class.new(
        object: object,
        relation: kessel_permission,
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

    # List workspaces where user has a specific permission
    # @param permission [String] Permission to check
    # @param user [User] User to check permission for
    # @return [Array<String>] Array of workspace IDs
    # rubocop:disable Metrics/MethodLength
    def list_workspaces_with_permission(permission:, user:)
      return [] unless enabled?

      kessel_permission = map_permission(permission)

      object_type = RepresentationType.new(
        resource_type: 'workspace',
        reporter_type: 'rbac'
      )
      subject = build_subject_reference(user)

      request = StreamedListObjectsRequest.new(
        object_type: object_type,
        relation: kessel_permission,
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

    # Get default workspace ID for organization
    # Delegates to Rbac service to avoid duplicating RBAC API logic
    # @param identity_header [String] Raw X-RH-IDENTITY header from request
    # @return [String] Default workspace ID
    delegate :get_default_workspace_id, to: :Rbac

    # Get root workspace ID for organization
    # Delegates to Rbac service to avoid duplicating RBAC API logic
    # @param identity_header [String] Raw X-RH-IDENTITY header from request
    # @return [String] Root workspace ID
    delegate :get_root_workspace_id, to: :Rbac

    private

    def build_client
      raise ConfigurationError, 'Kessel is not enabled' unless enabled?

      # Create gRPC client using the actual Kessel SDK API
      if Settings.kessel.insecure
        KesselInventoryService::Stub.new(Settings.kessel.url, :this_channel_is_insecure)
      else
        credentials = build_credentials
        KesselInventoryService::Stub.new(Settings.kessel.url, credentials)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to build Kessel client: #{e.message}")
      raise ConfigurationError, "Failed to build Kessel client: #{e.message}"
    end

    def build_credentials
      # Start with base TLS credentials
      credentials = GRPC::Core::ChannelCredentials.new

      # Add OAuth2 authentication if enabled
      if Settings.kessel.auth.enabled
        oauth_creds = build_oauth_credentials
        credentials = credentials.compose(oauth_creds)
      end

      credentials
    end

    # rubocop:disable Metrics/AbcSize
    def build_oauth_credentials
      # Fetch OIDC discovery metadata
      discovery = fetch_oidc_discovery(Settings.kessel.auth.oidc_issuer)

      # Create OAuth2 client credentials
      oauth = OAuth2ClientCredentials.new(
        client_id: Settings.kessel.auth.client_id,
        client_secret: Settings.kessel.auth.client_secret,
        token_endpoint: discovery.token_endpoint
      )

      # Return gRPC call credentials
      oauth2_call_credentials(oauth)
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

    def map_permission(rbac_permission)
      PERMISSION_MAPPINGS[rbac_permission] || rbac_permission.gsub(':', '_').gsub('*', 'all')
    end
  end
end
