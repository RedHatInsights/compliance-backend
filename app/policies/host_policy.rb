# frozen_string_literal: true

# Policies for accessing Hosts
class HostPolicy < ApplicationPolicy
  def index?
    match_account? && match_group?
  end

  def show?
    match_account? && match_group?
  end

  private

  def match_group?
    groups = user.inventory_groups
    # Global access || ungrouped host || group matching
    groups == Rbac::ANY || record.groups.blank? && groups&.include?([]) || record.group_ids.intersect?(groups)
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      groups = user.inventory_groups

      return scope.none if user.org_id.blank? || groups.blank?

      user_scope = scope.where(org_id: user.org_id)

      return user_scope if groups == Rbac::ANY # Global access

      user_scope.with_groups(groups)
    end
  end
end
