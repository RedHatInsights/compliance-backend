# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  def index
    render_json scope_search.sort_by(&:score)
  end

  def show
    authorize profile
    render_json profile
  end

  def create
    profile = Profile.new(profile_create_params.to_h)
                     .fill_from_parent
    if profile.save
      profile.add_rules(ids: profile_create_params[:rule_ids])
      render_json profile
    else
      render_error profile
    end
  end

  def update
    if profile.update(profile_update_params.to_h)
      render_json profile
    else
      render_error profile
    end
  end

  def destroy
    render_json profile.destroy, status: :accepted
  end

  def tailoring_file
    return unless profile.tailored?

    send_data XccdfTailoringFile.new(
      profile: profile,
      rule_ref_ids: profile.tailored_rule_ref_ids
    ).to_xml, filename: tailoring_filename, type: Mime[:xml]
  end

  private

  def tailoring_filename
    "#{profile.benchmark.ref_id}__#{profile.ref_id}__tailoring.xml"
  end

  def profile
    @profile ||= Pundit.policy_scope(current_user, resource).find(params[:id])
  end

  def resource
    Profile
  end

  def serializer
    ProfileSerializer
  end

  # Profile params
  module Params
    extend ActiveSupport::Concern

    included do
      private

      def profile_params
        params.require(:data)
              .require(:attributes)
              .permit(:description, :name, :compliance_threshold,
                      :business_objective_id)
      end

      def profile_create_params
        params.require(:data).require(:attributes).require(:parent_profile_id)
        params.require(:data).require(:attributes)
              .with_defaults(account_id: current_user.account_id)
              .permit(:description, :name, :compliance_threshold, :ref_id,
                      :business_objective_id, :rule_ids, :parent_profile_id)
      end

      def profile_update_params
        params.require(:data).require(:attributes)
              .permit(:name, :description,
                      :compliance_threshold, :business_objective_id)
      end
    end
  end; include Params
end
