# frozen_string_literal: true

module V2
  # API for Policy Systems
  class PolicySystemsController < ApplicationController
    def index
      render json: systems
    end

    def show
      render json: host
    end

    def update
      throw NotImplementedError
    end
  end
end
