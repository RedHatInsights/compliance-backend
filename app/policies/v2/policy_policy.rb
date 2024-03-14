# frozen_string_literal: true

module V2
  # Policies for accessing Policies
  class PolicyPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is handled in scoping
    end

    def show?
      match_account?
    end

    def update?
      match_account?
    end

    def destroy?
      match_account?
    end

    def systems?
      match_account? # TODO: inventory groups
    end

    # Only show policies in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        return scope.where('1=0') if user&.account_id.blank?

        scope.where(account_id: user.account_id)
      end
    end
  end
end
