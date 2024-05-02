# frozen_string_literal: true

module V2
  # API for Reports (rule results)
  class ReportsController < ApplicationController
    def index
      render_json reports
    end
    permission_for_action :index, Rbac::REPORT_READ

    def show
      render_json report
    end
    permission_for_action :show, Rbac::REPORT_READ

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
