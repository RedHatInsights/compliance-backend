# frozen_string_literal: true

module V2
  # Pundit Policies for accessing Compliance Policies
  class PolicyPolicy < ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    # Only show hosts in our user account
    class Scope < ::ApplicationPolicy::Scope
      def resolve
        return scope.where('1=0') if user&.account_id.blank?

        scope.where(account_id: user.account_id)
      end
    end
  end
end
