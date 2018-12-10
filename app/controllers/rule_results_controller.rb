# frozen_string_literal: true

# API for RuleResults
class RuleResultsController < ApplicationController
  def index
    render json: RuleResultSerializer.new(policy_scope(RuleResult).to_a)
  end
end
