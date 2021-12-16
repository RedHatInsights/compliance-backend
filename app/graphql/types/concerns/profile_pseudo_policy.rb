# frozen_string_literal: true

module Types
  module Concerns
    # Methods related to support pseudo-policy
    module ProfilePseudoPolicy
      extend ActiveSupport::Concern

      def name
        object.policy&.name || object.name
      end

      def description
        object.policy&.description || object.description
      end

      # Pseudo policy with a Profile type
      def policy
        return if object.canonical? || object.policy.nil?

        object.policy.initial_profile
      end

      # policy profiles
      def profiles
        return if object.canonical?

        object.policy&.profiles
      end
    end
  end
end
