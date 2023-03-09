# frozen_string_literal: true

module V2
  # API for SSG Rules
  class SsgRulesController < ApplicationController
    def index
      render json: rules
    end

    def show
      render json: rule
    end
  end
end
