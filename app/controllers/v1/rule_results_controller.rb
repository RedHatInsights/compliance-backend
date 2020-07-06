# frozen_string_literal: true

module V1
  # API for RuleResults
  class RuleResultsController < ApplicationController
    def index
      render_json scope_search
    end

    private

    def serializer
      RuleResultSerializer
    end

    def resource
      RuleResult
    end
  end
end
