# frozen_string_literal: true

# Policies for accessing Value Definitions
class ValueDefinitionPolicy < ApplicationPolicy
  def index?
    true
  end

  # All users should see all value definitions currently
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
