# frozen_string_literal: true

# Policies for accessing TestResults
class TestResultPolicy < ApplicationPolicy
  def index?
    Pundit.policy(user, record.profile) || Pundit.policy(user, record.host)
  end

  def show?
    Pundit.policy(user, record.profile) || Pundit.policy(user, record.host)
  end

  # Only show TestResults belonging to profiles owned by the current user
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      available_profiles = ProfilePolicy::Scope.new(user, ::Profile)
      available_hosts = HostPolicy::Scope.new(user, ::Host)
      scope.where(profile_id: available_profiles.resolve).or(
        scope.where(host_id: available_hosts.resolve)
      )
    end
  end
end
