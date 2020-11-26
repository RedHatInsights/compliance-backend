# frozen_string_literal: true

module Types
  # Methods related to system profiles and policies
  module SystemProfiles
    extend ActiveSupport::Concern

    def profiles(policy_id: nil)
      context_parent
      scope_profiles(object.all_profiles, policy_id)
    end

    def test_result_profiles(policy_id: nil)
      context_parent
      scope_profiles(object.test_result_profiles, policy_id)
    end

    def policies(policy_id: nil)
      context_parent
      policy_profiles = object.assigned_profiles.external(false)
      scope_profiles(policy_profiles, policy_id)
    end

    private

    def scope_profiles(profiles, policy_id)
      policy_id ? profiles.in_policy(policy_id) : profiles
    end
  end
end
