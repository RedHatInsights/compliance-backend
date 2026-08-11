# frozen_string_literal: true

# API for Rule Results
class RuleResultsController < ApplicationController
  def index
    render_json rule_results
  end
  permission_for_action :index, Rbac::REPORT_READ
  kessel_permission_for_action :index, KesselRbac::REPORT_VIEW

  private

  def rule_results
    @rule_results ||= authorize(resolve_collection)
  end

  def resource
    RuleResult
  end

  def serializer
    RuleResultSerializer
  end
end
