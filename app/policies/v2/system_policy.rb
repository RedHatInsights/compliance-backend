# frozen_string_literal: true

module V2
  # Policies for accessing Systems
  class SystemPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is handled in scoping
    end

    def show?
      match_account? && match_group?
    end

    def create?
      true
    end

    def update?
      match_account? && match_group?
    end

    def destroy?
      match_account? && match_group?
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

    # Only show systems in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        user.cert_authenticated? ? resolve_cert_auth : resolve_regular
      end

      private

      def resolve_regular
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
