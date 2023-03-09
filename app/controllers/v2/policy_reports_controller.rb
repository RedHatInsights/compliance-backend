# frozen_string_literal: true

module V2
  # API for Policy reports
  class PolicyReportsController < ApplicationController
    def index
      render json: reports
    end

    def show
      render json: report
    end
  end
end
