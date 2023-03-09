# frozen_string_literal: true

module V2
  # API for Value definitions
  class ValueDefinitionsController < ApplicationController
    def index
      render json: value_definitions
    end
  end
end
