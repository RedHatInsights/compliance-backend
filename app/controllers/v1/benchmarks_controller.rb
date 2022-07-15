# frozen_string_literal: true

module V1
  # API for Benchmarks
  class BenchmarksController < ApplicationController
    def index
      render_json benchmarks
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json benchmark
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

    private

    def benchmarks
      @benchmarks ||= authorize(resolve_collection)
    end

    def benchmark
      @benchmark ||= authorize(resource.find(permitted_params[:id]))
    end

    def scope
      policy_scope(resource)
    end

    def resource
      Xccdf::Benchmark
    end

    def serializer
      BenchmarkSerializer
    end

    def includes
      return unless permitted_params[:include]&.split(',')&.include?('rules')

      { rules: %i[profiles] }
    end
  end
end
