# frozen_string_literal: true

# REST API for Rules
class RulesController < ApplicationController
  def index
    render json: RuleSerializer.new(policy_scope(Rule).to_a)
  end

  def show
    rule = Rule.find(params[:id])
    authorize rule
    render json: RuleSerializer.new(rule)
  end
end
