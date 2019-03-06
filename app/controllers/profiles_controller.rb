# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    render json: ProfileSerializer.new(
      policy_scope(index_relation)
      .paginate(page: params[:page], per_page: params[:per_page])
      .sort_by(&:score)
    )
  end

  def index_relation
    relation = Profile.includes(:rules, :hosts)
    if profile_index_params[:hostname]
      relation = relation
                 .where(hosts: { name: profile_index_params[:hostname] })
                 .includes(:profile_hosts)
    end
    relation
  end

  def show
    profile = Profile.friendly.find(params[:id])
    authorize profile
    render json: ProfileSerializer.new(profile)
  end

  private

  def profile_index_params
    params.permit(:hostname)
  end
end
