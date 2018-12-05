# frozen_string_literal: true

# Policies for accessing users
class UserPolicy < ApplicationPolicy
  def show?
    record.id == user.id
  end

  # The only user visible should be our own
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.id)
    end
  end
end
