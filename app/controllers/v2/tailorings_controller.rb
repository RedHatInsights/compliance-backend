# frozen_string_literal: true

module V2
  # API for Tailorings
  class TailoringsController < ApplicationController
    CREATE_ATTRIBUTES = { os_minor_version: ParamType.integer & ParamType.gte(0) }.freeze
    UPDATE_ATTRIBUTES = { value_overrides: ParamType.map }.freeze

    def index
      render_json tailorings
    end
    permission_for_action :index, Rbac::POLICY_READ
    kessel_permission_for_action :index, KesselRbac::POLICY_VIEW

    def show
      render_json tailoring
    end
    permission_for_action :show, Rbac::POLICY_READ
    kessel_permission_for_action :show, KesselRbac::POLICY_VIEW

    def rule_tree
      render json: tailoring.rule_tree
    end
    permission_for_action :rule_tree, Rbac::COMPLIANCE_VIEWER
    kessel_permission_for_action :rule_tree, KesselRbac::POLICY_VIEW
    permitted_params_for_action :rule_tree, id: ID_TYPE.required

    def create
      # Look up the latest Profile supporting the given OS minor version
      new_tailoring = V2::Tailoring.for_policy(policy, permitted_params[:os_minor_version])
      new_tailoring.account = current_user.account

      if new_tailoring.save
        render_json new_tailoring, status: :created
        audit_success("Created tailoring #{new_tailoring.id}")
      else
        render_model_errors new_tailoring
      end
    end
    permission_for_action :create, Rbac::POLICY_WRITE
    kessel_permission_for_action :create, KesselRbac::POLICY_EDIT
    permitted_params_for_action :create, { id: ID_TYPE, **CREATE_ATTRIBUTES }

    def update
      if tailoring.update(permitted_params.to_h.slice(*UPDATE_ATTRIBUTES.keys))
        render_json tailoring, status: :accepted
        audit_success("Updated policy #{tailoring.id}")
      else
        render_model_errors tailoring
      end
    end
    permission_for_action :update, Rbac::POLICY_WRITE
    kessel_permission_for_action :update, KesselRbac::POLICY_EDIT
    permitted_params_for_action :update, { id: ID_TYPE, **UPDATE_ATTRIBUTES }

    def tailoring_file
      builder = file_builder(params[:format].to_sym)

      return if builder.empty? # no-content for empty XMLs

      send_data(builder.output, filename: builder.filename, type: builder.mime)
    end
    permission_for_action :tailoring_file, Rbac::POLICY_READ
    kessel_permission_for_action :tailoring_file, KesselRbac::POLICY_VIEW
    permitted_params_for_action :tailoring_file, id: ID_TYPE.required

    private

    def expand_resource
      scope = super

      # preloading associations to prevent N+1
      scope.includes(
        :rules,
        profile: :rules,
        policy: :profile,
        rules: :rule_group,
        security_guide: :value_definitions
      )
    end

    def tailorings
      @tailorings ||= authorize(fetch_collection)
    end

    def tailoring
      @tailoring ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def policy
      V2::Policy.find(permitted_params[:policy_id])
    end

    def file_builder(format)
      V2::TailoringFile.new(
        profile: tailoring,
        rules: tailoring.rules_added + tailoring.rules_removed,
        rule_group_ref_ids: tailoring.rule_group_ref_ids,
        set_values: tailoring.value_overrides_by_ref_id,
        format: format
      )
    end

    def resource
      V2::Tailoring
    end

    def serializer
      V2::TailoringSerializer
    end

    def extra_fields
      %i[policy_id]
    end
  end
end
