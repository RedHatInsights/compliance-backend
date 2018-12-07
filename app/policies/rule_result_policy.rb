# frozen_string_literal: true

# Policies for accessing RuleResults
class RuleResultPolicy < ApplicationPolicy
  def index?
    Pundit.policy(user, record.host)
  end

  def show?
    Pundit.policy(user, record.host)
  end

  # Only show RuleResults belonging to hosts visible by the current user
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.select { |_rule_result| Pundit.policy(user, record.host) }
    end
  end
end
