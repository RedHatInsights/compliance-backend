# frozen_string_literal: true

# API for RuleResults
module V1
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
