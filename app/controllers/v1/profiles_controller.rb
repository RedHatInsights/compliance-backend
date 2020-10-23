# frozen_string_literal: true

module V1
  # API for Profiles
  class ProfilesController < ApplicationController
    include InventoryServiceHelper
    include ProfileAttributes

    before_action only: %i[update] do
      error = 'Editing an external profile is forbidden.'
      render json: { errors: error }, status: :forbidden if profile.external?
    end

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
      Policy.transaction do
        if new_policy.save && new_profile.update(policy_object: new_policy)
          update_relationships
          render_json new_profile, status: :created
        else
          render_error [new_profile, new_policy]
          raise ActiveRecord::Rollback
        end
      end
    end

    def update
      Policy.transaction do
        if profile.policy_object.update(policy_update_attributes)
          update_relationships
          render_json profile
        else
          render_error profile
        end
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

    def new_profile
      @new_profile ||= Profile.new(profile_create_attributes).fill_from_parent
    end

    def new_policy
      @new_policy ||= Policy.new(policy_create_attributes)
                            .fill_from(profile: parent_profile)
    end

    def update_relationships
      add_inventory_hosts(new_host_ids || [])
      profile.policy_object.update_hosts(new_host_ids)
      profile.update_rules(ids: new_rule_ids)
    end

    def tailoring_filename
      "#{profile.benchmark.ref_id}__#{profile.ref_id}__tailoring.xml"
    end

    def profile
      @profile ||= @new_profile || pundit_scope.find(params[:id])
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
