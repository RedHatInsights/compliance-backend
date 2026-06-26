# frozen_string_literal: true

module V2
  # Policies for accessing Supported Profiles
  class SupportedProfilePolicy < V2::ApplicationPolicy
    def index?
      true
    end

    # All users should see all supported profiles
    class Scope < V2::ApplicationPolicy::Scope
    end
  end
end
