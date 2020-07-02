# frozen_string_literal: true

module V1
  # API for Benchmarks
  class BenchmarksController < ApplicationController
    def index
      render_json benchmarks
    end

    def show
      render_json benchmark
    end

    private

    def benchmarks
      @benchmarks ||= authorize(scope_search)
    end

    def benchmark
      @benchmark ||= authorize(resource.find(params[:id]))
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
  end
end
