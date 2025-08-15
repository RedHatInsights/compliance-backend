# frozen_string_literal: true

module V2
  # Policies for accessing Rule Results
  class RuleResultPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is handled in scoping
    end

    def show?
      match_account? && match_workspace?(record.system)
    end

    private

    def match_account?
      record.system.org_id == user.org_id
    end

    # Only show rule results in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        groups = user.inventory_groups

        return scope.none if user.org_id.blank? || groups.blank?

        base_scope = scope.where(system: { org_id: user.org_id })
        groups == Rbac::ANY ? base_scope : base_scope.with_groups(groups, V2::System.arel_table.alias(:system))
      end
    end
  end
end
