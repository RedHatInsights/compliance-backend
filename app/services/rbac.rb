# frozen_string_literal: true

require 'insights-rbac-api-client'

# This service is meant to handle calls to the RBAC API
class Rbac
  API_CLIENT = RBACApiClient::AccessApi.new
  COMPLIANCE_FULL_ACCESS = 'compliance:*:*'
  APPS = 'compliance,inventory'
  OPTS = { limit: 1000, auth_names: '' }.freeze
  ANY = '*'

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
        raise AuthorizationError
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
  end
end
