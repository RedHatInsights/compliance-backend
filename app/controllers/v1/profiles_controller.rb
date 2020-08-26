# frozen_string_literal: true

module V1
  # API for Profiles
  class ProfilesController < ApplicationController
    include InventoryServiceHelper

    ALLOWED_CREATE_ATTRIBUTES = %i[
      name description compliance_threshold business_objective
      parent_profile_id
    ].freeze

    ALLOWED_UPDATE_ATTRIBUTES = %i[
      name description compliance_threshold business_objective
    ].freeze

    before_action only: %i[show update] do
      authorize profile
    end

    def index
      params[:search] ||= 'external=false and canonical=false'
      render_json scope_search.sort_by(&:score)
    end

    def show
      render_json profile
    end

    def destroy
      authorize profile
      render_json profile.destroy, status: :accepted
    end

    def create
      @profile = Profile.new(profile_create_attributes).fill_from_parent

      if profile.save
        update_relationships
        render_json profile, status: :created
      else
        render_error profile
      end
    end

    def update
      if profile.update(profile_update_attributes)
        update_relationships
        render_json profile
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

    def update_relationships
      add_inventory_hosts(new_host_ids || [])
      profile.update_hosts(new_host_ids)
      profile.update_rules(ids: new_rule_ids)
    end

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
      ).from_title(resource_attributes&.dig(:business_objective))
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

    def profile_update_attributes
      resource_attributes.to_h.slice(*ALLOWED_UPDATE_ATTRIBUTES).tap do |attrs|
        if business_objective
          attrs.except! :business_objective
          attrs[:business_objective_id] = business_objective.id
        end
      end
    end

    def new_host_ids
      new_relationship_ids(:hosts)
    end

    def new_rule_ids
      new_relationship_ids(:rules)
    end

    def resource
      Profile
    end

    def serializer
      ProfileSerializer
    end
  end
end
