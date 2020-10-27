# frozen_string_literal: true

module Types
  # Methods related to support pseudo-policy
  module ProfilePseudoPolicy
    extend ActiveSupport::Concern

    # Pseudo policy with a Profile type
    # inheriting most of the attributes form the policy.
    def policy
      return if object.canonical? || object.policy_object.nil?

      policy = object.policy_object
      policy_profile = object.policy_object.initial_profile
      policy_profile.assign_attributes(
        name: policy.name,
        description: policy.description
      )
      policy_profile
    end
  end
end
