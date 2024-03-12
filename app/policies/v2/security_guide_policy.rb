# frozen_string_literal: true

module V2
  # Policies for accessing Security Guides
  class SecurityGuidePolicy < V2::ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    def rule_tree?
      true
    end

    # All users should see all security guides currently
    class Scope < V2::ApplicationPolicy::Scope
    end
  end
end
