# frozen_string_literal: true

module Mutations
  # Helpers for user related mutations
  module UserHelper
    def current_user
      @current_user ||= context[:current_user]
    end
  end

  # Helpers for host related mutations
  module HostHelper
    include UserHelper

    def find_host(host_id)
      ::Pundit.authorize(
        current_user,
        ::Host.find(host_id),
        :show?
      )
    end

    def find_hosts(host_ids)
      ::Pundit.policy_scope(current_user, ::Host)
              .where(id: host_ids)
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

  # Common class for all GraphQL mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    protected

    def audit_success(msg)
      Rails.logger.audit_success(msg)
    end
  end
end
