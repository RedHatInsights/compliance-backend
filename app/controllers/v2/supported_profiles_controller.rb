# frozen_string_literal: true

module V2
  # API for Supported Profiles
  class SupportedProfilesController < ApplicationController
    def index
      render_json supported_profiles
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    private

    def supported_profiles
      @supported_profiles ||= authorize(resolve_collection)
    end

    def resource
      V2::SupportedProfile
    end

    def serializer
      V2::SupportedProfileSerializer
    end
  end
end
