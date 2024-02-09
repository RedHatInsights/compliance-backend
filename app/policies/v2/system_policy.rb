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
        groups = user.inventory_groups

        # No access to systems if there is no org_id or any RBAC (group) rule available
        return scope.none if user.org_id.blank? || groups.blank?

        user_scope = scope.where(org_id: user.org_id)

        # All systems are available if there is global access
        return user_scope if groups == Rbac::ANY

        # Apply inventory group rules on the query
        user_scope.with_groups(groups)
      end
    end
  end
end
