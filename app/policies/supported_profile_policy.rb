# frozen_string_literal: true

# Policies for accessing Supported Profiles
class SupportedProfilePolicy < ApplicationPolicy
  def index?
    true
  end

  # All users should see all supported profiles
  class Scope < ApplicationPolicy::Scope
  end
end
