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

    # Use a lighter scope for counting that avoids the full serializer data
    # JOINs (profile, security_guide) that aren't needed just to count rows.
    def count_collection(_scope)
      @count_collection ||= begin
        count_scope = join_parents(pundit_scope, permitted_params[:parents])
                      .with_count_data
        count_scope = search(filter_by_tags(count_scope))
        count_scope.reselect(resource.base_class.count_by).count
      end
    end
  end
end
