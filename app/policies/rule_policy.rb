# frozen_string_literal: true

# Policies for accessing Rules
class RulePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # All users should see all rules
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
