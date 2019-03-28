# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    profiles = scope_search.sort_by(&:score)
    render json: ProfileSerializer.new(
      profiles,
      metadata(total: profiles.count)
    )
  end

  def show
    profile = Profile.friendly.find(params[:id])
    authorize profile
    render json: ProfileSerializer.new(profile)
  end

  private

  def resource
    Profile
  end
end
