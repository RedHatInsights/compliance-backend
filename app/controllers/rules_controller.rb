# frozen_string_literal: true

# REST API for Rules
class RulesController < ApplicationController
  def index
    render json: RuleSerializer.new(scope_search, metadata)
  end

  def show
    rule = ::Pundit.policy_scope(User.current, ::Rule).where(
      'rules.slug LIKE ?',
      "%#{ActiveRecord::Base.sanitize_sql_like(params[:id])}%"
    ).first
    raise ActiveRecord::RecordNotFound if rule.blank?

    render json: RuleSerializer.new(rule)
  end

  private

  def resource
    Rule
  end
end
