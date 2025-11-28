# frozen_string_literal: true

module V2
  # API for Rule Results
  class RuleResultsController < ApplicationController
    def index
      render_json rule_results
    end
    permission_for_action :index, Rbac::REPORT_READ
    kessel_permission_for_action :index, KesselRbac::REPORT_VIEW

    private

    def rule_results
      @rule_results ||= authorize(fetch_collection)
    end

    def resource
      V2::RuleResult
    end

    def serializer
      V2::RuleResultSerializer
    end

    def expand_resource
      scope = join_parents(pundit_scope, permitted_params[:parents])
      scope.with_serializer_data
    end
  end
end
