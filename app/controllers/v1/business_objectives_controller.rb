# frozen_string_literal: true

module V1
  # API for BusinessObjectives
  class BusinessObjectivesController < ApplicationController
    def index
      permitted_params[:sort_by] ||= 'title'
      render_json resolve_collection
    end
    permission_for_action :index, Rbac::POLICY_READ

    def show
      authorize business_objective
      render_json business_objective
    end
    permission_for_action :show, Rbac::POLICY_READ

    private

    def business_objective
      @business_objective ||= pundit_scope.find(permitted_params[:id])
    end

    def resource
      BusinessObjective
    end

    def serializer
      BusinessObjectiveSerializer
    end
  end
end
