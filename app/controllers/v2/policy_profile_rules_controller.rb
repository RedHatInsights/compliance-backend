# frozen_string_literal: true

module V2
  # API for Policy profile rules
  class PolicyProfileRulesController < ApplicationController
    def index
      render json: rules
    end
  end
end
