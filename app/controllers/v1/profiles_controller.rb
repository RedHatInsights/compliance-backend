# frozen_string_literal: true

module V1
  # API for Profiles
  class ProfilesController < ApplicationController
    include ProfileAttributes
    include ProfileAudit

    before_action(only: %i[show update]) { authorize profile }

    def index
      permitted_params[:search] ||= 'external=false and canonical=false'
      permitted_params[:sort_by] ||= 'score'
      render_json resolve_collection
    end
    permission_for_action :index, Rbac::COMPLIANCE_VIEWER

    def show
      render_json profile
    end
    permission_for_action :show, Rbac::COMPLIANCE_VIEWER

    def destroy
      authorize profile
      destroyed_profile = profile.destroy
      audit_removal(destroyed_profile)
      render_json destroyed_profile, status: :accepted
    end
    permission_for_action :destroy, Rbac::POLICY_DELETE

    def create
      Policy.transaction do
        if new_policy.save && new_profile.update(policy: new_policy)
          update_relationships
          render_json new_profile, status: :created
        else
          render_model_errors [new_profile, new_policy]
          raise ActiveRecord::Rollback
        end
      end
      audit_creation
    end
    permission_for_action :create, Rbac::POLICY_CREATE

    def update
      Policy.transaction do
        if profile.policy.update(policy_update_attributes) && profile.update(profile_update_attributes || {})
          update_relationships
          render_json profile
          audit_update
        else
          render_model_errors profile
        end
      end
    end
    permission_for_action :update, Rbac::POLICY_WRITE

    def tailoring_file
      return unless profile.tailored?

      send_data XccdfTailoringFile.new(
        profile: profile, rule_ref_ids: profile.tailored_rule_ref_ids,
        rule_group_ref_ids: profile.rule_group_ancestor_ref_ids
      ).to_xml, filename: tailoring_filename, type: Mime[:xml]

      audit_tailoring_file
    end
    permission_for_action :tailoring_file, Rbac::COMPLIANCE_VIEWER
    permitted_params_for_action :tailoring_file, id: ID_TYPE.required

    private

    attr_reader :hosts_added, :hosts_removed, :rules_added, :rules_removed

    def new_profile
      @new_profile ||= Profile.new(profile_create_attributes).fill_from_parent
    end

    def new_policy
      @new_policy ||= Policy.new(policy_create_attributes)
                            .fill_from(profile: parent_profile)
    end

    def update_relationships
      @hosts_added, @hosts_removed =
        profile.policy.update_hosts(new_host_ids)
      @rules_added, @rules_removed =
        profile.update_rules(ids: new_rule_ids)
    end

    def tailoring_filename
      "#{profile.benchmark.ref_id}__#{profile.ref_id}__tailoring.xml"
    end

    def profile
      @profile ||= @new_profile || pundit_scope.find(permitted_params[:id])
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
      new_relationship_ids(Host)
    end

    def new_rule_ids
      new_relationship_ids(Rule)
    end

    def resource
      Profile
    end

    def serializer
      ProfileSerializer
    end
  end
end
