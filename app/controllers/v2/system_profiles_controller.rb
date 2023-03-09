# frozen_string_literal: true

module V2
  # API for System Profiles
  class SystemProfilesController < ApplicationController
    def index
      render json: system_profiles
    end

    def show
      render json: system_profile
    end
  end
end
