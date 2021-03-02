# frozen_string_literal: true

module V1
  # API for Profiles
  class ProfilesController < ApplicationController
    include ProfileAttributes
    include ProfileAudit

    attr_reader :hosts_added, :hosts_removed, :rules_added, :rules_removed

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
      destroyed_profile = profile.destroy
      audit_removal(destroyed_profile)
      render_json destroyed_profile, status: :accepted
    end

    def create
      Policy.transaction do
        if new_policy.save && new_profile.update(policy_object: new_policy)
          update_relationships
          render_json new_profile, status: :created
        else
          render_model_errors [new_profile, new_policy]
          raise ActiveRecord::Rollback
        end
      end
      audit_creation
    end

    def update
      Policy.transaction do
        if profile.policy_object.update(policy_update_attributes)
          update_relationships
          render_json profile
          audit_update
        else
          render_model_errors profile
        end
      end
    end

    def tailoring_file
      return unless profile.tailored?

      send_data XccdfTailoringFile.new(
        profile: profile,
        rule_ref_ids: profile.tailored_rule_ref_ids
      ).to_xml, filename: tailoring_filename, type: Mime[:xml]

      audit_tailoring_file
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
      @hosts_added, @hosts_removed =
        profile.policy_object.update_hosts(new_host_ids)
      @rules_added, @rules_removed =
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
      ).from_title(resource_attributes&.dig(:business_objective)) do |new_bo|
        audit_bo_creation(new_bo)
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
