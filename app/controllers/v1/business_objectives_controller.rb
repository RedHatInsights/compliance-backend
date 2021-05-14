# frozen_string_literal: true

module V1
  # API for BusinessObjectives
  class BusinessObjectivesController < ApplicationController
    def index
      render_json resolve_collection.sort_by(&:title)
    end

    def show
      authorize business_objective
      render_json business_objective
    end

    private

    def business_objective
      @business_objective ||= pundit_scope.find(params[:id])
    end

    def resource
      BusinessObjective
    end

    def serializer
      BusinessObjectiveSerializer
    end
  end
end
