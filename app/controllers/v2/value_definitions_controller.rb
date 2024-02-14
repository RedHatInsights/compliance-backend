# frozen_string_literal: true

module V2
  # API for Value Definitions under Security Guides
  class ValueDefinitionsController < ApplicationController
    def index
      render_json value_definitions
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json value_definition
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

    private

    def value_definitions
      @value_definitions ||= authorize(fetch_collection)
    end

    def value_definition
      @value_definition ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::ValueDefinition
    end

    def serializer
      V2::ValueDefinitionSerializer
    end
  end
end
