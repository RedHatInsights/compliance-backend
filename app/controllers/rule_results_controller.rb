# frozen_string_literal: true

# API for RuleResults
class RuleResultsController < ApplicationController
  def index
    render json: RuleResultSerializer.new(RuleResult.all.to_a)
  end
end
