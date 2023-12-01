# frozen_string_literal: true

module V2
  # Policies for accessing Tailorings
  class TailoringPolicy < V2::ApplicationPolicy
    def index?
      true
    end

    def show?
      true
    end

    def tailoring_file?
      true # TODO: cert_auth
    end
  end

  # Only show tailoring in our user account
  class Scope < V2::ApplicationPolicy::Scope
    def resolve
      resolve scope.where('1=0') if user&.account_id.blank?

      scope
        .where
        .associated(:policy)
        .where(policy: { account_id: user.account_id })
    end
  end
end
