# frozen_string_literal: true

module V2
  # Policies for accessing Systems
  class SystemPolicy < V2::ApplicationPolicy
    def index?
      # KESSEL: This stays; handled in scoping
      true # FIXME: this is handled in scoping
    end

    def show?
      if KesselClient.enabled?
        kessel_system_check('view')
      else
        match_account? && match_group?
      end
    end

    def create?
      true
    end

    def update?
      if KesselClient.enabled?
        kessel_system_check('update')
      else
        match_account? && match_group?
      end
    end

    def destroy?
      if KesselClient.enabled?
        kessel_system_check('destroy')
      else
        match_account? && match_group?
      end
    end

    def os_versions?
      true
    end

    private

    def match_account?
      record.org_id == user.org_id
    end

    def match_group?
      groups = user.inventory_groups
      # Global access || ungrouped host || group matching
      (groups == Rbac::ANY) || (record.groups.blank? && groups&.include?([])) || record.group_ids.intersect?(groups)
    end

    # Kessel-based system authorization check
    def kessel_system_check(action)
      KesselClient.check_permission(
        resource_type: 'system',
        resource_id: record.id,
        permission: "compliance_system_#{action}",
        user: user,
        use_check_for_update: %w[update destroy].include?(action)
      )
    rescue KesselClient::AuthorizationError => e
      Rails.logger.error("Kessel system check failed: #{e.message}")
      false
    end

    # Only show systems in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        user.cert_authenticated? ? resolve_cert_auth : resolve_regular
      end

      # In aggregations, we should not join with all systems, so scoping them `org_id`
      def aggregate
        base_scope
      end

      private

      def resolve_regular
        # KESSEL: do the same OR consider doing workspace (inventory group) lookup here
        # This is because we know the verb here,
        # so we can do list_objects(workspace, view_systems, user)
        # I think you would still filter on org_id because this is effectively an implicit
        # query param, not an authorization function any more.
        # Cross org access will require making this "query param" explicit.
        # Cert auth path stays the same b/c we don't have cert auth identities (yet?)

        groups = user.inventory_groups

        # No access to systems if there is no org_id or any RBAC (group) rule available
        return scope.none if user.org_id.blank? || groups.blank?

        # Apply inventory group rules on the query if needed
        groups == Rbac::ANY ? base_scope : base_scope.with_groups(groups)
      end

      def resolve_cert_auth
        base_scope.where(V2::System::OWNER_ID.eq(user.system_owner_id))
      end

      def base_scope
        scope.where(org_id: user.org_id)
      end
    end
  end
end
