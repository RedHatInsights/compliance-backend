# frozen_string_literal: true

module V2
  # API for Profiles under Security Guides
  class ProfilesController < ApplicationController
    def index
      render_json profiles
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json profile
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

    private

    def profiles
      @profiles ||= authorize(resolve_collection)
    end

    def profile
      # FIXME: change after canonical_profiles becomes a table
      # rubocop:disable Rails/FindById
      @profile ||= authorize(resource.find_by!(id: permitted_params[:id]))
      # rubocop:enable Rails/FindById
    end

    def resource
      V2::Profile.where(security_guide_id: params[:security_guide_id])
    end

    def serializer
      V2::ProfileSerializer
    end
  end
end
