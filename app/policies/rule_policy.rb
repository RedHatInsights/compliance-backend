# frozen_string_literal: true

# Policies for accessing Rules
class RulePolicy < ApplicationPolicy
  def index?
    record.profiles.pluck(:account_id).include? user.id
  end

  def show?
    record.profiles.pluck(:account_id).include? user.id
  end

  # Only select Rules belonging to profiles visible by the current user
  # (profile account ID = rule account ID)
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      ids = scope.all.select do |rule|
        rule.profiles.pluck(:account_id).include? user.account_id
      end
      scope.where(id: ids)
    end
  end
end
