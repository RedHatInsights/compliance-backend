# frozen_string_literal: true

module V2
  # API for Rules under Security Guides
  class RulesController < ApplicationController
    include IndexableByRefId

    def index
      render_json rules
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json rule
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

    private

    def rules
      @rules ||= authorize(fetch_collection)
    end

    def rule
      @rule ||= authorize(ref_id_lookup(expand_resource, permitted_params[:id]))
    end

    def resource
      V2::Rule
    end

    def serializer
      V2::RuleSerializer
    end
  end
end
