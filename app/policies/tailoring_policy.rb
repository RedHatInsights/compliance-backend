# frozen_string_literal: true

# Policies for accessing Tailorings
class TailoringPolicy < ApplicationPolicy
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
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user&.account_id.blank?

      scope.where(policy_id: Policy.where(account_id: user.account_id).select(:id))
    end
  end
end
