# frozen_string_literal: true

module V2
  # API for Reports (rule results)
  class ReportsController < ApplicationController
    def index
      render_json reports
    end
    permission_for_action :index, Rbac::REPORT_READ
    kessel_permission_for_action :index, KesselRbac::REPORT_VIEW

    def show
      render_json report
    end
    permission_for_action :show, Rbac::REPORT_READ
    kessel_permission_for_action :show, KesselRbac::REPORT_VIEW

    def destroy
      report.delete_associated
      audit_success("Removed report #{report.id}")
      render_json report, status: :accepted
    end
    permission_for_action :destroy, Rbac::POLICY_DELETE
    kessel_permission_for_action :destroy, KesselRbac::POLICY_REMOVE
    permitted_params_for_action :destroy, { id: ID_TYPE }

    def stats
      render json: {
        top_failed_rules: report.top_failed_rules.map { |r| r.attributes.compact }
      }, status: :ok
    end
    permitted_params_for_action :stats, id: ParamType.string
    permission_for_action :stats, Rbac::REPORT_READ
    kessel_permission_for_action :stats, KesselRbac::REPORT_VIEW

    # :nocov:
    def os_versions
      render json: reports.os_versions, status: :ok
    end
    # :nocov:
    permission_for_action :os_versions, Rbac::SYSTEM_READ
    permitted_params_for_action :os_versions, { filter: ParamType.string }
    kessel_permission_for_action :os_versions, KesselRbac::SYSTEM_VIEW

    private

    def reports
      @reports ||= authorize(fetch_collection)
    end

    def report
      @report ||= authorize(expand_resource.find(permitted_params[:id]))
    end

    def resource
      V2::Report
    end

    def serializer
      V2::ReportSerializer
    end

    def extra_fields
      %i[account_id]
    end
  end
end
