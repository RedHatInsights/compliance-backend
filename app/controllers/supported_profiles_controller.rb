# frozen_string_literal: true

# API for Supported Profiles
class SupportedProfilesController < ApplicationController
  def index
    render_json supported_profiles
  end
  permission_for_action :index, Rbac::COMPLIANCE_VIEWER
  kessel_permission_for_action :index, KesselRbac::POLICY_VIEW

  private

  def supported_profiles
    @supported_profiles ||= authorize(resolve_collection)
  end

  def resource
    SupportedProfile
  end

  def serializer
    SupportedProfileSerializer
  end
end
