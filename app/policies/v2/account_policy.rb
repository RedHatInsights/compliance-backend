# frozen_string_literal: true

module V2
  # Policies for accessing Accounts
  class AccountPolicy < ApplicationPolicy
    # Only our account should be visible
    class Scope < ::ApplicationPolicy::Scope
      def resolve
        scope.where(id: user.account_id)
      end
    end
  end
end
