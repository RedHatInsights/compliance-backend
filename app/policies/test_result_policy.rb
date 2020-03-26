# frozen_string_literal: true

# Policies for accessing TestResults
class TestResultPolicy < ApplicationPolicy
  def index?
    Pundit.policy(user, record.profile)
  end

  def show?
    Pundit.policy(user, record.profile)
  end

  # Only show TestResults belonging to profiles owned by the current user
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      available_profiles = HostPolicy::Scope.new(user, ::Profile).resolve.pluck(:id)
      scope.where(profile_id: available_profiles)
    end
  end
end
