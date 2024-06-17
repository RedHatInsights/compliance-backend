# frozen_string_literal: true

module V2
  # Policies for accessing Test Results
  class TestResultPolicy < V2::ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    class Scope < V2::ApplicationPolicy::Scope
      # def resolve
      #   groups = user.inventory_groups

      #   return scope.none if user.org_id.blank? || groups.blank?

      #   base_scope = scope.joins(:system).where(system: { org_id: user.org_id })
      #   groups == Rbac::ANY ? base_scope : base_scope.with_groups(groups)

      # end
    end
  end
end
