# frozen_string_literal: true

# API for Test Results under Reports
class TestResultsController < ApplicationController
  def index
    render_json test_results
  end
  permission_for_action :index, Rbac::REPORT_READ
  kessel_permission_for_action :index, KesselRbac::REPORT_VIEW

  def show
    render_json test_result
  end
  permission_for_action :show, Rbac::REPORT_READ
  kessel_permission_for_action :show, KesselRbac::REPORT_VIEW

  def rule_tree
    render json: test_result.tailoring.rule_tree
  end
  permission_for_action :rule_tree, Rbac::REPORT_READ
  kessel_permission_for_action :rule_tree, KesselRbac::REPORT_VIEW
  permitted_params_for_action :rule_tree, id: ID_TYPE.required

  def os_versions
    render json: authorize(fetch_collection(base_scope)).os_versions, status: :ok
  end
  permission_for_action :os_versions, Rbac::SYSTEM_READ
  permitted_params_for_action :os_versions, {
    filter: ParamType.string,
    tags: ParamType.array(ParamType.string) | ParamType.string
  }

  def security_guide_versions
    render json: test_results.security_guide_versions, status: :ok
  end
  permission_for_action :security_guide_versions, Rbac::REPORT_READ
  kessel_permission_for_action :security_guide_versions, KesselRbac::REPORT_VIEW
  permitted_params_for_action :security_guide_versions, {
    filter: ParamType.string,
    tags: ParamType.array(ParamType.string) | ParamType.string
  }

  private

  def test_results
    @test_results ||= authorize(resolve_collection)
  end

  def test_result
    @test_result ||= authorize(filter_by_tags(expand_resource).find(permitted_params[:id]), :show?)
  end

  def resource
    TestResult
  end

  def serializer
    TestResultSerializer
  end

  def extra_fields
    %i[tailoring_id]
  end
end
