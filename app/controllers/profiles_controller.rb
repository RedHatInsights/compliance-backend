# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    render json: ProfileSerializer.new(
      Profile.includes(:rules, :hosts).all.to_a
    )
  end

  def show
    render json: ProfileSerializer.new(Profile.find(params[:id]))
  end
end
