# frozen_string_literal: true

# Policies for accessing Profiles
class ProfilePolicy < ApplicationPolicy
  def index?
    match_account?
  end

  def show?
    match_account?
  end

  # Only show hosts in our user account
  class Scope < ::ApplicationPolicy::Scope
    def resolve
      only_matching_account
    end
  end
end
