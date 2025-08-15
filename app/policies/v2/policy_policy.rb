# frozen_string_literal: true

module V2
  # Policies for accessing Policies
  class PolicyPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is handled in scoping
    end

    # KESSEL: all of these would be replaced with check(default_workspace, permission, user)
    def show?
      if KesselClient.enabled?
        kessel_default_workspace_check('compliance_policy_view')
      else
        match_account?
      end
    end

    def update?
      if KesselClient.enabled?
        kessel_default_workspace_check('compliance_policy_write')
      else
        match_account?
      end
    end

    def destroy?
      if KesselClient.enabled?
        kessel_default_workspace_check('compliance_policy_delete')
      else
        match_account?
      end
    end

    private

    # Kessel-based default workspace authorization check
    def kessel_default_workspace_check(permission)
      # Get the raw identity header from the current request context
      # This requires access to the controller's raw_identity_header method
      identity_header = user.account.identity_header.raw
      default_workspace_id = KesselClient.get_default_workspace_id(identity_header)
      
      KesselClient.check_permission(
        resource_type: 'workspace',
        resource_id: default_workspace_id,
        permission: permission,
        user: user,
        use_check_for_update: permission.include?('write') || permission.include?('delete')
      )
    rescue KesselClient::AuthorizationError => e
      Rails.logger.error("Kessel policy check failed: #{e.message}")
      false
    end

    # Only show policies in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        # KESSEL: i think this stays the same, because you're not doing fine grained authorization
        # with kessel at a policy level.
        # In the future this would be joined with list_objects(Policy, view, user)
        # Or list_objects(Workspace, view_policies, user) 
        # (and then joined with the Policies workspaces, like inventory groups are used with hosts)
        return scope.none if user&.account_id.blank?

        scope.where(account_id: user.account_id)
      end
    end
  end
end
