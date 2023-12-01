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

    def tailoring_file?
      user.cert_authenticated?
    end

    # Only show tailoring in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        resolve scope.where('1=0') if user&.account_id.blank?

        scope.where
             .associated(:policy)
             .where(policy: { account_id: user.account_id })
      end
    end
  end
end
