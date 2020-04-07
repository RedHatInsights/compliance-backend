# frozen_string_literal: true

# Policies for accessing BusinessObjectives
class BusinessObjectivePolicy < ApplicationPolicy
  def index?
    record.account_ids.include? user.account_id
  end

  def show?
    record.account_ids.include? user.account_id
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.in_account(user.account_id)
    end
  end
end
