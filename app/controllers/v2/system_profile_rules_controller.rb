# frozen_string_literal: true

module V2
  # API for System Profile Rules
  class SystemProfileRulesController < ApplicationController
    def index
      render json: rules
    end
  end
end
