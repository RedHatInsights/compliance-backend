# frozen_string_literal: true

module V2
  # API for Profiles under Security Guides
  class ProfilesController < ApplicationController
    include IndexableByRefId

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
      @profile ||= authorize(ref_id_lookup(expand_resource, permitted_params[:id]))
    end

    def resource
      V2::Profile
    end

    def serializer
      V2::ProfileSerializer
    end
  end
end
