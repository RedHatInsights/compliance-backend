# frozen_string_literal: true

module V1
  # REST API for Value Definitions
  class ValueDefinitionsController < ApplicationController
    def index
      render_json resolve_collection
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    private

    def resource
      ValueDefinition
    end

    def serializer
      ValueDefinitionSerializer
    end

    def includes
      %i[benchmark]
    end
  end
end
