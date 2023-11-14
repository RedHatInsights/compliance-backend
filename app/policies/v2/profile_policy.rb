# frozen_string_literal: true

module V2
  # Policies for accessing Profiles
  class ProfilePolicy < V2::ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    # All users should see all Profiles currently
    class Scope < V2::ApplicationPolicy::Scope
    end
  end
end
