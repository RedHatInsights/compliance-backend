# frozen_string_literal: true

# Policies for accessing BusinessObjectives
class BusinessObjectivePolicy < ApplicationPolicy
  def index?
    record.profiles.pluck(:account_id).include? user.account_id
  end

  def show?
    record.profiles.pluck(:account_id).include? user.account_id
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      ids = scope.all.select do |business_objective|
        business_objective.profiles.pluck(:account_id).include? user.account_id
      end
      scope.where(id: ids)
    end
  end
end
