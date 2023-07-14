# frozen_string_literal: true

# Policies for accessing Hosts
class HostPolicy < ApplicationPolicy
  def index?
    match_account?
  end

  def show?
    match_account?
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      return scope.none if user.org_id.blank?

      scope.where(org_id: user.org_id).non_edge
    end
  end
end
