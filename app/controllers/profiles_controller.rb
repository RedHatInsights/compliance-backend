# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    render json: ProfileSerializer.new(scope_search.sort_by(&:score), metadata)
  end

  def show
    profile = Profile.find(params[:id])
    authorize profile
    render json: ProfileSerializer.new(profile)
  end

  private

  def resource
    Profile
  end
end
