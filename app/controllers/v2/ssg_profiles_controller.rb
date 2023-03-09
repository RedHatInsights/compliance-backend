# frozen_string_literal: true

module V2
  # API for SSG Profiles
  class SsgProfilesController < ApplicationController
    def index
      render json: { ssg: 'Profiles' }
    end

    def show
      render json: { ssg: 'Profile' }
    end
  end
end
