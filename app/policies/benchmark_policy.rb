# frozen_string_literal: true

# Policies for accessing Benchmarks
class BenchmarkPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # Only select Rules belonging to profiles visible by the current user
  # (profile account ID = rule account ID)
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
