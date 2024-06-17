# frozen_string_literal: true

module V2
  # API for Test Results under Reports
  class TestResultsController < ApplicationController
    def index
      render_json test_results
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json test_result
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

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
