# frozen_string_literal: true

# Policies for accessing Benchmarks
class OsMajorVersionPolicy < ApplicationPolicy
  # All users should see all benchmarks currently
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
