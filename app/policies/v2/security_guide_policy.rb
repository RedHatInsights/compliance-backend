# frozen_string_literal: true

module V2
  # Policies for accessing Security Guides
  class SecurityGuidePolicy < ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    # All users should see all security guides currently
    class Scope < ::ApplicationPolicy::Scope
      def resolve
        scope.all
      end
    end
  end
end
