# frozen_string_literal: true

module V2
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

    def os_versions
      render json: test_results.os_versions, status: :ok
    end
    permission_for_action :os_versions, Rbac::SYSTEM_READ
    kessel_permission_for_action :os_versions, KesselRbac::SYSTEM_VIEW
    permitted_params_for_action :os_versions, { filter: ParamType.string }

    def security_guide_versions
      render json: test_results.security_guide_versions, status: :ok
    end
    permission_for_action :security_guide_versions, Rbac::REPORT_READ
    kessel_permission_for_action :security_guide_versions, KesselRbac::REPORT_VIEW
    permitted_params_for_action :security_guide_versions, { filter: ParamType.string }

    private

    def test_results
      @test_results ||= authorize(fetch_collection)
    end

    def test_result
      @test_result ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::TestResult
    end

    def serializer
      V2::TestResultSerializer
    end
  end
end
