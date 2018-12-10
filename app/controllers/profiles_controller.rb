# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    render json: ProfileSerializer.new(
      policy_scope(Profile.includes(:rules, :hosts)).to_a
    )
  end

  def show
    profile = Profile.find(params[:id])
    authorize profile
    render json: ProfileSerializer.new(profile)
  end
end
