# frozen_string_literal: true

# Policies for accessing Hosts
class HostPolicy < ApplicationPolicy
  def index?
    match_account?
  end

  def show?
    match_account?
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      return scope.none if user.account_number.blank?

      scope.where(account: user.account_number)
    end
  end
end
