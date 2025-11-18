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
      check_enablement
      ActiveModel::Type::Boolean.new.cast(Settings.kessel.enabled)
    end

    def check_enablement
      unleash_ff_enabled = Rails.configuration.unleash.is_enabled?('compliance.kessel_enabled', @unleash_context)

      if !Settings.kessel.enabled && unleash_ff_enabled
        Settings.kessel.enabled = true
        Rails.logger.info 'Kessel feature flag has been enabled'
      elsif Settings.kessel.enabled && !unleash_ff_enabled
        Settings.kessel.enabled = false
        Rails.logger.info 'Kessel feature flag has been disabled'
      end
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
        response.allowed
      rescue StandardError => e
        Rails.logger.error("Kessel authorization check failed: #{e.message}")
        raise AuthorizationError, "Authorization check failed: #{e.message}"
      end
    end

    def list_workspaces_with_permission(permission:, user:)
      return [] unless enabled?

      request = list_workspaces_request(permission, user)

      begin
        response = client.streamed_list_objects(request)
        response.map(&:object).map(&:resource_id)
      rescue StandardError => e
        Rails.logger.error("Kessel workspace listing failed: #{e.message}")
        raise AuthorizationError, "Workspace listing failed: #{e.message}"
      end
    end

    private

    delegate :get_default_workspace_id, to: :KesselUtils
    delegate :build_client, to: :KesselBuilder
    delegate :auth, to: :KesselBuilder

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

    def list_workspaces_request(permission, user)
      StreamedListObjectsRequest.new(
        object_type: workspace_type,
        relation: permission,
        subject: build_subject_reference(user)
      )
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
