# frozen_string_literal: true

# Policies for accessing Profiles
class ProfilePolicy < ApplicationPolicy
  def index?
    match_account? || record.account_id.blank?
  end

  def show?
    match_account? || record.account_id.blank?
  end

  def update?
    match_account?
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      return scope.where('1=0') if user&.account_id.blank?

      scope.where(account_id: user.account_id)
    end
  end
end
