# frozen_string_literal: true

# Policies for accessing Profiles
class ProfilePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def rule_tree?
    true
  end

  # All users should see all Profiles currently
  class Scope < ApplicationPolicy::Scope
  end
end
