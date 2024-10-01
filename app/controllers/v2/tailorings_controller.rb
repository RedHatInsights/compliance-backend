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

    def show
      render_json tailoring
    end
    permission_for_action :show, Rbac::POLICY_READ

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
    permitted_params_for_action :update, { id: ID_TYPE, **UPDATE_ATTRIBUTES }

    def tailoring_file
      return unless tailoring.tailored?

      format = params[:format].to_sym
      send_data(build_file(format), filename: filename(format), type: Mime[format])
    end
    permission_for_action :tailoring_file, Rbac::POLICY_READ
    permitted_params_for_action :tailoring_file, id: ID_TYPE.required

    private

    def tailorings
      @tailorings ||= authorize(fetch_collection)
    end

    def tailoring
      @tailoring ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def policy
      V2::Policy.find(permitted_params[:policy_id])
    end

    def build_file(format)
      builder = format == :json ? JsonTailoringFile : XccdfTailoringFile

      builder.new(
        profile: tailoring,
        rules: tailoring.rules_added + tailoring.rules_removed,
        rule_group_ref_ids: tailoring.rule_group_ref_ids,
        set_values: tailoring.value_overrides_by_ref_id
      ).output
    end

    def filename(format)
      extension = format == :json ? 'json' : 'xml'

      "#{tailoring.security_guide.ref_id}__#{tailoring.profile.ref_id}__tailoring.#{extension}"
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
