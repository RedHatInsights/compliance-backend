# frozen_string_literal: true

module V1
  # API for RuleResults
  class RuleResultsController < ApplicationController
    def index
      render json: RuleResultSerializer.new(scope_search, metadata)
    end

    private

    def resource
      RuleResult
    end
  end
end
