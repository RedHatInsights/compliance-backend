# frozen_string_literal: true

module V2
  # API for Profiles under Security Guides
  class ProfilesController < ApplicationController
    def index
      render_json profiles
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :index, KesselRbac::POLICY_VIEW

    def show
      render_json profile
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :show, KesselRbac::POLICY_VIEW

    def rule_tree
      render json: profile.rule_tree
    end
    permission_for_action :rule_tree, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :rule_tree, KesselRbac::POLICY_VIEW
    permitted_params_for_action :rule_tree, id: ID_TYPE.required

    private

    def profiles
      @profiles ||= authorize(fetch_collection)
    end

    def profile
      @profile ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::Profile
    end

    def serializer
      V2::ProfileSerializer
    end

    def extra_fields
      %i[security_guide_id]
    end
  end
end
