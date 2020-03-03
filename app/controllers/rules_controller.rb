# frozen_string_literal: true

# REST API for Rules
class RulesController < ApplicationController
  def index
    render json: RuleSerializer.new(scope_search, metadata)
  end

  def show
    rule = if ::UUID.validate(params[:id])
             search_by_id
           else
             search_by_ref_id
           end

    raise ActiveRecord::RecordNotFound if rule.blank?

    render json: RuleSerializer.new(rule)
  end

  private

  def resource
    Rule
  end

  def search_by_id
    ::Pundit.policy_scope(User.current, ::Rule).friendly.find(params[:id])
  end

  def search_by_ref_id
    rule = Rule.canonical.where(
      'rules.slug LIKE ?',
      "%#{ActiveRecord::Base.sanitize_sql_like(params[:id])}%"
    )
    raise ActiveRecord::RecordNotFound if rule.blank?

    rule.first
  end
end
