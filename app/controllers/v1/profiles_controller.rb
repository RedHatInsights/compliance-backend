# frozen_string_literal: true

module V1
  # API for Profiles
  class ProfilesController < ApplicationController
    ALLOWED_CREATE_ATTRIBUTES = %i[
      name description compliance_threshold business_objective
      parent_profile_id
    ].freeze

    def index
      params[:search] ||= 'external=false and canonical=false'
      render_json scope_search.sort_by(&:score)
    end

    def show
      authorize profile
      render_json profile
    end

    def destroy
      authorize profile
      render_json profile.destroy, status: :accepted
    end

    def create
      profile = Profile.new(profile_create_attributes).fill_from_parent

      if profile.save
        profile.update_rules(ids: new_rule_ids)
        render_json profile, status: :created
      else
        render_error profile
      end
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
      @profile ||= pundit_scope.find(params[:id])
    end

    def parent_profile
      @parent_profile ||= pundit_scope.find(
        resource_attributes.require(:parent_profile_id)
      )
    end

    def business_objective
      @business_objective ||= Pundit.policy_scope(
        current_user, BusinessObjective
      ).from_title(resource_attributes[:business_objective])
    end

    def profile_create_attributes
      resource_attributes.to_h.slice(*ALLOWED_CREATE_ATTRIBUTES)
                         .merge(account_id: current_user.account_id)
                         .tap do |attrs|
        parent_profile

        if business_objective
          attrs.except! :business_objective
          attrs[:business_objective_id] = business_objective.id
        end
      end
    end

    def new_rule_ids
      resource_relationships.to_h.dig(:rules, :data)&.map do |rule|
        rule[:id]
      end
    end

    def resource
      Profile
    end

    def serializer
      ProfileSerializer
    end
  end
end
