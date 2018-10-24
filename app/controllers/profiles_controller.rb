class ProfilesController < ApplicationController
  def index
    render json: ProfileSerializer.new(Profile.all.to_a)
  end
end
