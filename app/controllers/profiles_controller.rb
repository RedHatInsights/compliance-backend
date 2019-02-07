# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    render json: ProfileSerializer.new(
      policy_scope(Profile.includes(:rules, :hosts))
      .paginate(page: params[:page], per_page: params[:per_page])
      .sort_by(&:score)
    )
  end

  def show
    profile = Profile.friendly.find(params[:id])
    authorize profile
    render json: ProfileSerializer.new(profile)
  end
end
