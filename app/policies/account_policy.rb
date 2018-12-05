# frozen_string_literal: true

# Policies for accessing Accounts
class AccountPolicy < ApplicationPolicy
  # Only our account should be visible
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.account_id)
    end
  end
end
