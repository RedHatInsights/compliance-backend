# frozen_string_literal: true

# Policies for accessing RuleGroups
class RuleGroupPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # All users should see all rule groups correctly
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
