# frozen_string_literal: true

require 'insights-rbac-api-client'

# This service is meant to handle calls to the RBAC API
class Rbac
  API_CLIENT = RBACApiClient::AccessApi.new
  APPS = 'compliance,inventory'
  OPTS = { limit: 1000, auth_names: '' }.freeze
  ANY = '*'

  INVENTORY_UNGROUPED_ENTRIES = [].freeze
  INVENTORY_HOSTS_READ = 'inventory:hosts:read'
  V1_COMPLIANCE_VIEWER = 'compliance:policy:read'
  COMPLIANCE_VIEWER = 'compliance:*:read'
  COMPLIANCE_ADMIN = 'compliance:*:*'
  POLICY_READ = 'compliance:policy:read'
  POLICY_CREATE = 'compliance:policy:create'
  POLICY_DELETE = 'compliance:policy:delete'
  POLICY_WRITE = 'compliance:policy:write'
  REPORT_READ = 'compliance:report:read'
  SYSTEM_READ = 'compliance:system:read'

  class AuthorizationError < StandardError; end

  class << self
    def load_user_permissions(identity)
      begin
        API_CLIENT.get_principal_access(
          self::APPS,
          self::OPTS.merge(header_params: { 'X-RH-IDENTITY': identity })
        ).data
      rescue RBACApiClient::ApiError => e
        Rails.logger.info(e.message)
        raise AuthorizationError, e.message
      end
    end

    def load_inventory_groups(permissions)
      # KESSEL: I think this is equivalent to list_objects(Workspace, view_systems, user)
      # Note `verify` call is checking for inventory:hosts:read
      # Just that this accepts the permissions already loaded as a parameter, whereas
      # there is no equivalent with Kessel
      # (you would just ask the initial question directly, see callers)

      permissions.each_with_object([]) do |permission, ids|
        next unless verify(permission.permission, INVENTORY_HOSTS_READ)
        # Empty array on 'resource_definitions' symbolizes a global access to the permitted resource.
        # In such case, the method returns Rbac::ANY and skips parsing of attribute_filter.
        return ANY if permission.resource_definitions == []

        permission.resource_definitions.each do |filter|
          next unless valid_inventory_groups_definition?(filter.attribute_filter)

          ids.append(*inventory_groups_definition_value(filter.attribute_filter))
        end
      end
    end

    # Get default workspace ID for organization using RBAC v2 API
    # @param identity_header [String] Raw X-RH-IDENTITY header from request
    # @return [String] Default workspace ID
    def get_default_workspace_id(identity_header)
      get_workspace_id_by_type('default', identity_header)
    end

    # Get root workspace ID for organization using RBAC v2 API
    # @param identity_header [String] Raw X-RH-IDENTITY header from request
    # @return [String] Root workspace ID
    def get_root_workspace_id(identity_header)
      get_workspace_id_by_type('root', identity_header)
    end

    # Get workspace ID by type using RBAC v2 API
    # @param workspace_type [String] Type of workspace ('default' or 'root')
    # @param identity_header [String] Raw X-RH-IDENTITY header from request
    # @return [String] Workspace ID
    def get_workspace_id_by_type(workspace_type, identity_header)
      # Extract org_id from identity header for caching
      parsed_identity = Insights::Api::Common::IdentityHeader.new(identity_header)
      org_id = parsed_identity.org_id

      # Cache workspace IDs since they're guaranteed to never change
      cache_key = "workspace_#{workspace_type}_#{org_id}"
      return @workspace_cache[cache_key] if @workspace_cache&.key?(cache_key)

      # Make RBAC v2 API call to get workspace
      # GET /v2/workspaces?type={workspace_type}
      # Use the actual identity header from the request
      workspace_id = fetch_workspace_from_rbac_v2(workspace_type, identity_header)

      # Cache the result
      @workspace_cache ||= {}
      @workspace_cache[cache_key] = workspace_id

      workspace_id
    rescue StandardError => e
      Rails.logger.error("Failed to get #{workspace_type} workspace ID for org #{org_id}: #{e.message}")
      raise AuthorizationError, "Failed to get #{workspace_type} workspace ID: #{e.message}"
    end

    def verify(permitted, requested)
      permitted_access = structurize(permitted)
      requested_access = structurize(requested)

      # Reject access, when requesting a different application
      return false if permitted_access.app != requested_access.app

      # Reject permission, when the user does not have access to (any) resource
      return false if permitted_access.resource != ANY &&
                      permitted_access.resource != requested_access.resource

      permitted_access.action == ANY ||
        permitted_access.action == requested_access.action
    end

    private

    # Fetch workspace from RBAC v2 API
    # @param workspace_type [String] Type of workspace ('default' or 'root')
    # @param identity_header [String] Raw X-RH-IDENTITY header from request
    # @return [String] Workspace ID
    def fetch_workspace_from_rbac_v2(workspace_type, identity_header)
      require 'faraday'
      require 'json'

      # Build RBAC API URL using existing configuration pattern
      # This uses the same configuration as the existing RBAC client
      rbac_base_url = if Settings.respond_to?(:endpoints) && Settings.endpoints.respond_to?(:rbac)
                        "#{Settings.endpoints.rbac.scheme}://#{Settings.endpoints.rbac.host}"
                      else
                        # Fallback for local development
                        'http://localhost:8000'
                      end

      conn = Faraday.new(url: rbac_base_url) do |f|
        f.request :url_encoded
        f.response :json
        f.adapter Faraday.default_adapter
      end

      response = conn.get('/v2/workspaces') do |req|
        req.params['type'] = workspace_type
        req.headers['X-RH-IDENTITY'] = identity_header
        req.headers['Content-Type'] = 'application/json'
      end

      if response.success?
        workspaces = response.body
        workspace = workspaces.dig('data')&.first
        if workspace&.dig('id')
          workspace['id']
        else
          parsed_identity = Insights::Api::Common::IdentityHeader.new(identity_header)
          data_array = workspaces.dig('data') || []
          raise "No #{workspace_type} workspace found for org #{parsed_identity.org_id}. Response contained #{data_array.length} workspaces."
        end
      else
        raise "RBAC API error: #{response.status} - #{response.body}"
      end
    end

    def structurize(access_entry)
      app, resource, action = access_entry.split(':')
      OpenStruct.new(app: app, resource: resource, action: action)
    end

    def valid_inventory_groups_definition?(definition)
      definition.value.instance_of?(Array) &&
        definition.operation == 'in' &&
        definition.key == 'group.id'
    end

    def inventory_groups_definition_value(definition)
      # Received '[nil]' symbolizes access to ungrouped entries.
      # In output represtented with an empty array.
      definition.value.map { |dv| dv || [] }
    end
  end
end
