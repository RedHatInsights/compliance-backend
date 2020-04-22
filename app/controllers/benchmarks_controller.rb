# frozen_string_literal: true

# API for Benchmarks
class BenchmarksController < ApplicationController
  def index
    render json: benchmarks
  end

  def show
    render json: benchmark
  end

  private

  def benchmarks
    @benchmarks ||= BenchmarkSerializer.new(authorize(scope_search), metadata)
  end

  def benchmark
    @benchmark ||= BenchmarkSerializer.new(
      authorize(resource.find(params[:id]))
    )
  end

  def scope
    policy_scope(resource)
  end

  def resource
    Xccdf::Benchmark
  end
end
