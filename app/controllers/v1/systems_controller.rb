# frozen_string_literal: true

module V1
  # API for Systems (only Hosts for the moment)
  class SystemsController < ApplicationController
    def index
      permitted_params[:search] ||= 'has_test_results=true or has_policy=true'
      render_json resolve_collection
    end
    permission_for_action :index, Rbac::SYSTEM_READ

    def show
      render_json host
    end
    permission_for_action :show, Rbac::SYSTEM_READ

    private

    def host
      @host ||= pundit_scope.find(permitted_params[:id])
    end

    def serializer
      HostSerializer
    end

    def resource
      Host
    end

    def includes
      %i[policy_hosts]
    end
  end
end
