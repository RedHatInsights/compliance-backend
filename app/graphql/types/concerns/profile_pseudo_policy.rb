# frozen_string_literal: true

module Types
  # Methods related to support pseudo-policy
  module ProfilePseudoPolicy
    extend ActiveSupport::Concern

    def name
      object.policy_object&.name || object.name
    end

    def description
      object.policy_object&.description || object.description
    end

    # Pseudo policy with a Profile type
    def policy
      return if object.canonical? || object.policy_object.nil?

      object.policy_object.initial_profile
    end

    # policy profiles
    def profiles
      return if object.canonical?

      object.policy_object&.profiles
    end
  end
end
