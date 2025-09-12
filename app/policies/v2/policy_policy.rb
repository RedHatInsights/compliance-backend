# frozen_string_literal: true

module V2
  # Policies for accessing Policies
  class PolicyPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is handled in scoping
    end

    def show?
      if Kessel.enabled?
        kessel_default_workspace_check('compliance_policy_view')
      else
        match_account?
      end
    end

    def update?
      if Kessel.enabled?
        kessel_default_workspace_check('compliance_policy_write')
      else
        match_account?
      end
    end

    def destroy?
      if Kessel.enabled?
        kessel_default_workspace_check('compliance_policy_delete')
      else
        match_account?
      end
    end

    private

    # Kessel-based default workspace authorization check
    # rubocop:disable Metrics/MethodLength
    def kessel_default_workspace_check(permission)
      # Get the raw identity header from the current request context
      # This requires access to the controller's raw_identity_header method
      identity_header = user.account.identity_header.raw
      default_workspace_id = Kessel.get_default_workspace_id(identity_header)

      Kessel.check_permission(
        resource_type: 'workspace',
        resource_id: default_workspace_id,
        permission: permission,
        user: user,
        use_check_for_update: permission.include?('write') || permission.include?('delete')
      )
    rescue Kessel::AuthorizationError => e
      Rails.logger.error("Kessel policy check failed: #{e.message}")
      false
    end
    # rubocop:enable Metrics/MethodLength

    # Only show policies in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        return scope.none if user&.account_id.blank?

        scope.where(account_id: user.account_id)
      end
    end
  end
end
