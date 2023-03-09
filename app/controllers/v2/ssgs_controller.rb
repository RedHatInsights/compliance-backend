# frozen_string_literal: true

module V2
  # API for SCAP Security Guides
  class SsgsController < ApplicationController
    def index
      render json: ssgs
    end

    def show
      render json: ssg
    end

    def ssgs
      @ssgs = Xccdf::Benchmark.all
    end

    def ssg
      SupportedSsg.find(params[:id])
    end
  end
end
