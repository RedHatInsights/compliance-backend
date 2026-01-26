# frozen_string_literal: true

require 'kessel-sdk'
require 'kessel/inventory/v1beta2/inventory_service_services_pb'
require_relative 'kessel_utils'

# Service for interacting with Kessel for RBAC v2 authorization
class KesselRbac
  class AuthorizationError < StandardError; end

  POLICY_VIEW = 'compliance_policy_view'
  POLICY_NEW = 'compliance_policy_new'
  POLICY_EDIT = 'compliance_policy_edit'
  POLICY_REMOVE = 'compliance_policy_remove'
  SYSTEM_VIEW = 'compliance_system_view'
  REPORT_VIEW = 'compliance_report_view'

  USER_IDENTITY = 'User'
  SERVICE_IDENTITY = 'ServiceAccount'

  class << self
    def enabled?
      ActiveModel::Type::Boolean.new.cast(Settings.kessel.enabled)
    end

    def client
      @client ||= build_client
    end

    include Kessel::Inventory::V1beta2
    include Kessel::RBAC::V2

    def default_permission_allowed?(permission, user)
      return false unless permission

      check_permission(
        resource_type: 'workspace',
        resource_id: get_default_workspace_id(auth, user.account.identity_header.raw),
        permission: permission,
        user: user
      )
    end

    def check_permission(resource_type:, resource_id:, permission:, user:, reporter_type: 'rbac')
      return true unless enabled?

      object = build_resource_reference(resource_type, resource_id, reporter_type)
      subject = build_subject_reference(user)
      begin
        response = run_check_permission(object, permission, subject)
        response.allowed == :ALLOWED_TRUE
      rescue StandardError => e
        Rails.logger.error("Kessel authorization check failed: #{e.message}")
        raise AuthorizationError, "Authorization check failed: #{e.message}"
      end
    end

    def list_workspaces_with_permission(permission:, user:)
      return [] unless enabled?

      # Check if user has permission on root workspace (org-level access)
      # If yes, return Rbac::ANY to avoid expensive JSONB queries
      return Rbac::ANY if root_workspace_access?(permission, user)

      # Otherwise, list specific workspaces the user has access to
      response = list_workspaces(client, build_subject_reference(user), permission)
      response.map(&:object).map(&:resource_id)
    rescue StandardError => e
      Rails.logger.error("Kessel workspace listing failed: #{e.message}")
      raise AuthorizationError, "Workspace listing failed: #{e.message}"
    end

    private

    delegate :get_default_workspace_id, to: :KesselUtils
    delegate :get_root_workspace_id, to: :KesselUtils
    delegate :build_client, to: :KesselBuilder
    delegate :auth, to: :KesselBuilder

    # Check if user has root workspace access (falls back to workspace listing on error)
    def root_workspace_access?(permission, user)
      check_permission(
        resource_type: 'workspace',
        resource_id: get_root_workspace_id(auth, user.account.identity_header.raw),
        permission: permission,
        user: user,
        reporter_type: 'rbac'
      )
    rescue StandardError => e
      Rails.logger.debug { "Root workspace check failed: #{e.message}" }
      false
    end

    def build_resource_reference(resource_type, resource_id, reporter_type)
      ResourceReference.new(
        resource_type: resource_type,
        resource_id: resource_id,
        reporter: ReporterReference.new(type: reporter_type)
      )
    end

    def run_check_permission(object, permission, subject)
      update = update_permission?(permission)
      klass = update ? CheckForUpdateRequest : CheckRequest
      request = klass.new(
        object: object,
        relation: permission,
        subject: subject
      )
      method = update ? :check_for_update : :check
      client.public_send(method, request)
    end

    def update_permission?(permission)
      permission.exclude?('view')
    end

    def principal_id(user)
      identity = user.account.identity_header.identity

      identity_type = identity&.dig('type')

      if identity_type == SERVICE_IDENTITY
        identity&.dig('service_account', 'user_id')
      elsif identity_type == USER_IDENTITY
        identity&.dig('user', 'user_id')
      else
        raise 'unsupported identity type'
      end
    end

    def build_subject_reference(user)
      principal_subject(principal_id(user), Settings.kessel.principal_domain)
    end
  end
end
