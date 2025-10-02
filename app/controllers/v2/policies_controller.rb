# frozen_string_literal: true

module V2
  # Controller for Policies
  class PoliciesController < ApplicationController
    CREATE_ATTRIBUTES = {
      title: ParamType.string,
      description: ParamType.string,
      business_objective: ParamType.string,
      compliance_threshold: ParamType.integer | ParamType.float,
      profile_id: ID_TYPE
    }.freeze
    UPDATE_ATTRIBUTES = CREATE_ATTRIBUTES.except(:title, :profile_id).freeze

    def index
      render_json compliance_policies
    end
    permission_for_action :index, Rbac::POLICY_READ
    kessel_permission_for_action :index, KesselRbac::POLICY_VIEW

    def show
      render_json compliance_policy
    end
    permission_for_action :show, Rbac::POLICY_READ
    kessel_permission_for_action :show, KesselRbac::POLICY_VIEW

    def create
      new_policy = V2::Policy.new(account: current_user.account, **permitted_params.to_h.slice(*CREATE_ATTRIBUTES.keys))

      if new_policy.save
        render_json new_policy, status: :created
        audit_success("Created policy #{new_policy.id}")
      else
        render_model_errors new_policy
      end
    end
    permission_for_action :create, Rbac::POLICY_CREATE
    kessel_permission_for_action :create, KesselRbac::POLICY_NEW
    permitted_params_for_action :create, CREATE_ATTRIBUTES

    def update
      if compliance_policy.update(permitted_params.to_h.slice(*UPDATE_ATTRIBUTES.keys))
        render_json compliance_policy, status: :accepted
        audit_success("Updated policy #{compliance_policy.id}")
      else
        render_model_errors compliance_policy
      end
    end
    permission_for_action :update, Rbac::POLICY_WRITE
    kessel_permission_for_action :update, KesselRbac::POLICY_EDIT
    permitted_params_for_action :update, { id: ID_TYPE, **UPDATE_ATTRIBUTES }

    def destroy
      compliance_policy.delete_associated
      compliance_policy.delete
      audit_success("Removed policy #{compliance_policy.id}")
      render_json compliance_policy, status: :accepted
    end
    permission_for_action :destroy, Rbac::POLICY_DELETE
    kessel_permission_for_action :destroy, KesselRbac::POLICY_REMOVE
    permitted_params_for_action :destroy, { id: ID_TYPE }

    private

    def compliance_policies
      @compliance_policies ||= authorize(fetch_collection)
    end

    def compliance_policy
      @compliance_policy ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::Policy
    end

    def serializer
      V2::PolicySerializer
    end

    def extra_fields
      %i[account_id profile_id]
    end
  end
end
