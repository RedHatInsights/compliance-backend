# frozen_string_literal: true

# Policies for accessing Policies
class PolicyPolicy < ApplicationPolicy
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

  # Only show policies in our user account
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user&.account_id.blank?

      scope.where(account_id: user.account_id)
    end
  end
end
