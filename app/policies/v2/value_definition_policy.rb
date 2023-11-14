# frozen_string_literal: true

module V2
  # Policies for accessing Value Definitions
  class ValueDefinitionPolicy < V2::ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    # All users should see all value definitions currently
    class Scope < V2::ApplicationPolicy::Scope
    end
  end
end
