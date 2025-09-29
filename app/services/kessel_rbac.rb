# frozen_string_literal: true

require 'kessel-sdk'
require 'kessel/inventory/v1beta2/inventory_service_services_pb'
require_relative 'kessel_utils'

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
  SECURITY_GUIDE_VIEW = 'compliance_securityguide_view'

  class << self
    def client
      @client ||= build_client
    end

    def auth
      @auth ||= build_oauth_credentials
    end

    include Kessel::Inventory::V1beta2

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

    def build_resource_reference(resource_type, resource_id, reporter_type)
      ResourceReference.new(
        resource_type: resource_type,
        resource_id: resource_id,
        reporter: ReporterReference.new(type: reporter_type)
      )
    end

    def run_check_permission(object, permission, subject)
      update = update_permission?(permission)
      request_class = update ? CheckForUpdateRequest : CheckRequest
      request_class.new(
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
        object_type: workspace_object_type,
        relation: permission,
        subject: build_subject_reference(user)
      )
    end

    def workspace_object_type
      RepresentationType.new(
        resource_type: 'workspace',
        reporter_type: 'rbac'
      )
    end

    def principal_id(user)
      identity = user.account.identity_header.identity

      identity_type = identity&.dig('type')

      if identity_type == 'ServiceAccount'
        identity&.dig('service_account', 'user_id')
      elsif identity_type == 'User'
        identity&.dig('user', 'user_id')
      else
        raise 'unsupported identity type'
      end
    end

    def build_subject_reference(user)
      SubjectReference.new(
        resource: ResourceReference.new(
          resource_type: 'principal',
          resource_id: "redhat/#{principal_id(user)}",
          reporter: ReporterReference.new(type: 'rbac')
        )
      )
    end
  end
end
