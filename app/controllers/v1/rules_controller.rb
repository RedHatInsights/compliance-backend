# frozen_string_literal: true

module V1
  # REST API for Rules
  class RulesController < ApplicationController
    def index
      render_json resolve_collection
    end

    def show
      rule = if ::UUID.validate(params[:id])
               search_by_id
             else
               search_by_ref_id
             end

      raise ActiveRecord::RecordNotFound if rule.blank?

      render_json rule
    end

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
      pundit_scope.friendly.find(params[:id])
    end

    def search_by_ref_id
      rule = pundit_scope.latest.where(
        'rules.slug LIKE ?',
        "%#{ActiveRecord::Base.sanitize_sql_like(params[:id])}%"
      )
      raise ActiveRecord::RecordNotFound if rule.blank?

      rule.first
    end
  end
end
