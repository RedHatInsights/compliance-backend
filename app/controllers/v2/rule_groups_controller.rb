# frozen_string_literal: true

module V2
  # API for Rule Groups under Security Guides
  class RuleGroupsController < ApplicationController
    def index
      render_json rule_groups
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :index, KesselRbac::POLICY_VIEW

    def show
      render_json rule_group
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :show, KesselRbac::POLICY_VIEW

    private

    def rule_groups
      @rule_groups ||= authorize(fetch_collection)
    end

    def rule_group
      @rule_group ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::RuleGroup
    end

    def serializer
      V2::RuleGroupSerializer
    end
  end
end
