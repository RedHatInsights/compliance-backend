# frozen_string_literal: true

# API for Profiles
class ProfilesController < ApplicationController
  ALLOWED_CREATE_ATTRIBUTES = %i[
    name description compliance_threshold business_objective_id
    parent_profile_id
  ].freeze

  ALLOWED_UPDATE_ATTRIBUTES = %i[
    name description compliance_threshold business_objective_id
  ].freeze

  def index
    render_json scope_search.sort_by(&:score)
  end

  def show
    authorize profile
    render_json profile
  end

  def create
    profile = Profile.new(profile_create_attributes)
                     .fill_from_parent
    if profile.save
      render_json profile
    else
      render_error profile
    end
  end

  def update
    if profile.update(profile_update_attributes)
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

  def parent_profile
    @parent_profile ||= Pundit.policy_scope(current_user, resource)
                              .find(profile_params[:parent_profile_id])
  end

  def resource
    Profile
  end

  def serializer
    ProfileSerializer
  end

  def profile_params
    params.require(:data).require(:attributes)
          .permit(serializer.attributes_to_serialize.keys)
  end

  def profile_create_attributes
    profile_params.to_h.slice(*ALLOWED_CREATE_ATTRIBUTES)
                  .merge(account_id: current_user.account_id).tap do
      parent_profile
    end
  end

  def profile_update_attributes
    profile_params.to_h.slice(*ALLOWED_UPDATE_ATTRIBUTES)
                  .merge(account_id: current_user.account_id)
  end
end
