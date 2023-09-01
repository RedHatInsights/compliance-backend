# frozen_string_literal: true

module V2
  # API for Security Guides
  class SecurityGuidesController < ApplicationController
    def index
      render_json security_guides
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json security_guide
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

    private

    def security_guides
      @security_guides ||= authorize(resolve_collection)
    end

    def security_guide
      @security_guide ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def scope
      policy_scope(resource)
    end

    def resource
      V2::SecurityGuide
    end

    def serializer
      V2::SecurityGuideSerializer
    end
  end
end
