# frozen_string_literal: true

module V2
  # API for reports
  class ReportsController < ApplicationController
    def index
      render json: reports
    end

    def reports
      TestResult.all
    end
  end
end
