# frozen_string_literal: true

module V2
  # Policies for accessing Rule Groups
  class RuleGroupPolicy < V2::ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    # All users should see all rules currently
    class Scope < ::ApplicationPolicy::Scope
    end
  end
end
