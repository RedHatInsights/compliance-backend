# frozen_string_literal: true

module V2
  # API for Systems
  class SystemsController < ApplicationController
    def index
      render json: systems
    end

    def show
      render json: system
    end

    def systems
      Host.all
    end

    def system
      Host.find(params[:id])
    end
  end
end
