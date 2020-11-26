# frozen_string_literal: true

module Types
  # Methods related to system profiles and policies
  module SystemProfiles
    extend ActiveSupport::Concern

    def profiles(policy_id: nil)
      context_parent
      all_profiles = object.all_profiles
      all_profiles = all_profiles.in_policy(policy_id) if policy_id
      all_profiles
    end
  end
end
