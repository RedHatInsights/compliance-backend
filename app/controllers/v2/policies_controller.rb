# frozen_string_literal: true

module V2
  # Controller for policies
  class PoliciesController < ApplicationController
    def index
      render_json compliance_policies
    end
    permission_for_action :index, Rbac::POLICY_READ

    def show
      render_json compliance_policy
    end
    permission_for_action :show, Rbac::POLICY_READ



    private

    def compliance_policies
      @compliance_policies ||= authorize(resolve_collection)
    end

    def compliance_policy
      @compliance_policy ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::Policy
    end

    def serializer
      V2::PolicySerializer
    end
  end
end
