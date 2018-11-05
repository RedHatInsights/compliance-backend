# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    render json: ProfileSerializer.new(Profile.all.to_a)
  end
end
