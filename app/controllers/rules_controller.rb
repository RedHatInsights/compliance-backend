# frozen_string_literal: true

# REST API for Rules
class RulesController < ApplicationController
  def index
    render json: RuleSerializer.new(scope_search, metadata)
  end

  def show
    rule = ::Pundit.policy_scope(User.current, ::Rule).friendly.find(
      params[:id]
    )
    render json: RuleSerializer.new(rule)
  end

  private

  def resource
    Rule
  end
end
