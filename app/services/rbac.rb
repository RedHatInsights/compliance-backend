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
  COMPLIANCE_VIEWER = 'compliance:policy:read' # universal read permission accross all roles
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
          self::OPTS.merge(header_params: { X_RH_IDENTITY: identity })
        ).data
      rescue RBACApiClient::ApiError => e
        Rails.logger.info(e.message)
        raise AuthorizationError, e.message
      end
    end

    def load_inventory_groups(permissions)
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

    def structurize(access_entry)
      app, resource, action = access_entry.split(':')
      OpenStruct.new(app: app, resource: resource, action: action)
    end

    def valid_inventory_groups_definition?(definition)
      definition[:value].instance_of?(Array) &&
        definition[:operation] == 'in' &&
        definition[:key] == 'group.id'
    end

    def inventory_groups_definition_value(definition)
      # Received '[nil]' symbolizes access to ungrouped entries.
      # In output represtented with an empty array.
      definition[:value].map { |dv| dv || [] }
    end
  end
end
