# frozen_string_literal: true

module V2
  # API for Policy profiles
  class PolicyProfilesController < ApplicationController
    def index
      render json: profiles
    end

    def show
      render json: profile
    end
  end
end
