# frozen_string_literal: true

# Policies for accessing Benchmarks
class OsMajorVersionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # All users should see all benchmarks currently
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
