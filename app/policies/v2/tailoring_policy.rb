# frozen_string_literal: true

module V2
  # Policies for accessing Tailorings
  class TailoringPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is hanled in scoping
    end

    def show?
      match_account?
    end

    def rule_tree?
      match_account?
    end

    def update?
      match_account?
    end

    def tailoring_file?
      match_account?
    end

    # Only show tailoring in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        resolve scope.none if user&.account_id.blank?

        scope.where
             .associated(:policy)
             .where(policy: { account_id: user.account_id })
      end
    end
  end
end
