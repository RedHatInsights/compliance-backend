# frozen_string_literal: true

module V1
  # API for RuleResults
  class RuleResultsController < ApplicationController
    def index
      render_json resolve_collection
    end
    permission_for_action :index, Rbac::POLICY_READ

    private

    def serializer
      RuleResultSerializer
    end

    def resource
      RuleResult
    end
  end
end
