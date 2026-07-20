# frozen_string_literal: true

# Policies for accessing Security Guides
class SecurityGuidePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def rule_tree?
    true
  end

  def os_versions?
    true
  end

  # All users should see all security guides currently
  class Scope < ApplicationPolicy::Scope
  end
end
