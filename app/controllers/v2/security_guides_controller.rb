# frozen_string_literal: true

module V2
  # API for Security Guides
  class SecurityGuidesController < ApplicationController
    def index
      render_json security_guides
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :index, KesselRbac::POLICY_VIEW

    def show
      render_json security_guide
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :show, KesselRbac::POLICY_VIEW

    def rule_tree
      render json: security_guide.rule_tree
    end
    permission_for_action :rule_tree, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :rule_tree, KesselRbac::POLICY_VIEW
    permitted_params_for_action :rule_tree, id: ID_TYPE.required

    def os_versions
      render json: security_guides.os_versions, status: :ok
    end
    permission_for_action :os_versions, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :os_versions, KesselRbac::POLICY_VIEW
    permitted_params_for_action :os_versions, { filter: ParamType.string }

    private

    def security_guides
      @security_guides ||= authorize(fetch_collection)
    end

    def security_guide
      @security_guide ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::SecurityGuide
    end

    def serializer
      V2::SecurityGuideSerializer
    end
  end
end
