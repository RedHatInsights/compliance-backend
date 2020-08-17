# frozen_string_literal: true

module Mutations
  # Helpers for user related mutations
  module UserHelper
    def current_user
      @current_user ||= context[:current_user]
    end
  end

  # Helpers for profile related mutations
  module ProfileHelper
    include UserHelper

    def find_profiles(profile_ids)
      ::Pundit.policy_scope(current_user, ::Profile)
              .where(id: profile_ids)
    end

    def find_profile(profile_id, permission: :edit?)
      ::Pundit.authorize(
        current_user,
        ::Profile.find(profile_id),
        permission
      )
    end
  end

  class BaseMutation < GraphQL::Schema::RelayClassicMutation
  end
end
