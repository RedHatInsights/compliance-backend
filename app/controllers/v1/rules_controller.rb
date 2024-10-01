# frozen_string_literal: true

module V1
  # REST API for Rules
  class RulesController < ApplicationController
    def index
      render_json resolve_collection
    end
    permission_for_action :index, Rbac::V1_COMPLIANCE_VIEWER
    permitted_params_for_action :index, policy_id: ID_TYPE

    def show
      rule = if ::UUID.validate(permitted_params[:id])
               search_by_id
             else
               search_by_ref_id
             end

      raise ActiveRecord::RecordNotFound if rule.blank?

      render_json rule
    end
    permission_for_action :show, Rbac::V1_COMPLIANCE_VIEWER

    private

    def resource
      Rule
    end

    def serializer
      RuleSerializer
    end

    def includes
      [profiles: :benchmark]
    end

    def search_by_id
      pundit_scope.friendly.find(permitted_params[:id])
    end

    def search_by_ref_id
      rule = pundit_scope.latest.where(
        'rules.slug LIKE ?',
        "%#{ActiveRecord::Base.sanitize_sql_like(permitted_params[:id])}%"
      )
      raise ActiveRecord::RecordNotFound if rule.blank?

      rule.first
    end
  end
end
